/*
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/company_product_enquiry_model.dart';
import '../../api/api_service.dart';
import 'approved_enquiries_screen.dart';
import 'company_product_enquiry_screen.dart'; // PendingEnquiryTable import

class EnquiryTabsScreen extends StatefulWidget {
  const EnquiryTabsScreen({super.key});

  @override
  State<EnquiryTabsScreen> createState() => _EnquiryTabsScreenState();
}

class _EnquiryTabsScreenState extends State<EnquiryTabsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime? fromDate;
  DateTime? toDate;

  String? fromDateApi;
  String? toDateApi;
  List<PendingEnquiry> allPending = [];
  List<PendingEnquiry> sentPending = [];

  bool isLoadingPending = true;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this); // Only 2 tabs now

    toDate = DateTime.now();

    fromDate = DateTime(
      toDate!.year,
      toDate!.month - 2,
      toDate!.day,
    );

    fromDateApi = DateFormat('yyyy-MM-dd').format(fromDate!);
    toDateApi = DateFormat('yyyy-MM-dd').format(toDate!);

    _loadPendingData();
  }

  Future<void> _loadPendingData() async {
    try {
      final response = await PendingEnquiryService.fetchPendingEnquiries(
        fromDate: fromDateApi,
        toDate: toDateApi,
      );
      if (mounted) {
        setState(() {
          allPending = response.data;
          sentPending = response.data.where((e) => e.isSentToCompany == true).toList();
          isLoadingPending = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoadingPending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load pending enquiries")),
        );
      }
    }
  }

  Future<void> pickFromDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        fromDate = picked;
        fromDateApi = DateFormat('yyyy-MM-dd').format(picked);
        isLoadingPending = true;
      });
      await _loadPendingData();
    }
  }

  Future<void> pickToDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: toDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        toDate = picked;
        toDateApi = DateFormat('yyyy-MM-dd').format(picked);
        isLoadingPending = true;
      });
      await _loadPendingData();
    }
  }

  Future<void> _handleSend(PendingEnquiry enquiry) async {
    try {
      final response = await EnquiryListService.sendEnquiryToCompany(enquiry.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message), backgroundColor: Colors.green),
      );
      setState(() {
        allPending.removeWhere((e) => e.id == enquiry.id);
        sentPending.removeWhere((e) => e.id == enquiry.id);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  // Navigate to Approved Enquiries Screen
  void _navigateToApprovedEnquiries() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ApprovedEnquiriesScreen()),
    );
  }

  Widget _buildDateFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: pickFromDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 18, color: Color(0xFF4158D0)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        fromDate != null
                            ? DateFormat('dd/MM/yyyy').format(fromDate!)
                            : 'From Date',
                        style: TextStyle(
                          color: fromDate != null ? Colors.black : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.arrow_forward, color: Color(0xFF4158D0), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: pickToDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 18, color: Color(0xFF4158D0)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        toDate != null
                            ? DateFormat('dd/MM/yyyy').format(toDate!)
                            : 'To Date',
                        style: TextStyle(
                          color: toDate != null ? Colors.black : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () async {
              setState(() {
                toDate = DateTime.now();
                fromDate = DateTime(
                  toDate!.year,
                  toDate!.month - 2,
                  toDate!.day,
                );
                fromDateApi = DateFormat('yyyy-MM-dd').format(fromDate!);
                toDateApi = DateFormat('yyyy-MM-dd').format(toDate!);
                isLoadingPending = true;
              });
              await _loadPendingData();
            },
            icon: const Icon(Icons.refresh, color: Color(0xFF4158D0)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF4158D0),
          labelColor: const Color(0xFF4158D0),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: "ALL Enquiry"),
            Tab(text: "Send Enquiry"),
          ],
        ),
        title: const Text("Enquiry Management",
            style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          // ✅ Approved Enquiries Button
          TextButton.icon(
            onPressed: _navigateToApprovedEnquiries,
            icon: const Icon(Icons.check_circle, color: Color(0xFF4158D0)),
            label: const Text(
              "Approved",
              style: TextStyle(color: Color(0xFF4158D0), fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildDateFilter(),
          const Divider(
            height: 2,
            thickness: 2,
            color: Color(0xFF4158D0),
            indent: 16,
            endIndent: 16,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                isLoadingPending
                    ? const Center(child: CircularProgressIndicator())
                    : PendingEnquiryTable(
                  initialData: allPending,
                  onSend: _handleSend,
                  showSendButton: true,
                ),
                isLoadingPending
                    ? const Center(child: CircularProgressIndicator())
                    : PendingEnquiryTable(
                  initialData: sentPending,
                  onSend: _handleSend,
                  showSendButton: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}*/
