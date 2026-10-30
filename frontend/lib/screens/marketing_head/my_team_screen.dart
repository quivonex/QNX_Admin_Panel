// lib/screens/marketing_head/my_team_screen.dart
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' as excel;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:html' as html;
import '../../api/marketing_service.dart';
import '../../models/marketing_head/my_team_model.dart';
import '../../models/marketing_head/partner_company_model.dart';
import 'partner_companies_screen.dart'; // now imports PartnerCompaniesView

class MyTeamScreen extends StatefulWidget {
  const MyTeamScreen({super.key});

  @override
  State<MyTeamScreen> createState() => _MyTeamScreenState();
}

class _MyTeamScreenState extends State<MyTeamScreen> {
  final ReferralPartnerService _service = ReferralPartnerService();

  List<MyReferredPartner> allPartners = [];
  List<MyReferredPartner> filteredPartners = [];
  List<MyReferredPartner> paginatedPartners = [];

  bool isLoading = true;
  String? error;

  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  String filterType = 'Name';

  int currentPage = 1;
  int itemsPerPage = 10;
  int totalPages = 1;
  final List<int> rowsPerPageOptions = [5, 10, 15, 20, 25, 30, 50];

  final Map<int, TableColumnWidth> columnWidths = const {
    0: FixedColumnWidth(50),
    1: FixedColumnWidth(150),
    2: FixedColumnWidth(55),
    3: FixedColumnWidth(170),
    4: FixedColumnWidth(100),
    5: FixedColumnWidth(120),
    6: FixedColumnWidth(70),
    7: FixedColumnWidth(80),
    8: FixedColumnWidth(90),
    9: FixedColumnWidth(70),
  };

  final List<String> headerLabels = [
    "ID", "Full Name", "Profile", "Email", "Mobile",
    "Working Area", "Team Size", "Status", "Created", "Actions"
  ];

  bool _showCompaniesView = false;
  MyReferredPartner? _selectedPartner;
  List<PartnerCompany> _selectedPartnerCompanies = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final response = await _service.getMyReferredPartners();
      if (response.status) {
        setState(() {
          allPartners = response.data;
          filteredPartners = List.from(allPartners);
          _applyPagination();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  void _applyFilters() {
    if (searchQuery.isEmpty) {
      filteredPartners = List.from(allPartners);
    } else {
      final query = searchQuery.toLowerCase();
      filteredPartners = allPartners.where((p) {
        switch (filterType) {
          case 'Name':
            return p.fullName.toLowerCase().contains(query);
          case 'Email':
            return p.email.toLowerCase().contains(query);
          case 'Mobile':
            return p.mobile.contains(query);
          case 'Status':
            return p.status.toLowerCase().contains(query);
          default:
            return false;
        }
      }).toList();
    }
    _applyPagination();
  }

  void _applyPagination() {
    if (filteredPartners.isEmpty) {
      paginatedPartners = [];
      totalPages = 1;
      currentPage = 1;
      setState(() {});
      return;
    }
    totalPages = (filteredPartners.length / itemsPerPage).ceil();
    if (currentPage > totalPages) currentPage = totalPages;
    if (currentPage < 1) currentPage = 1;
    int start = (currentPage - 1) * itemsPerPage;
    int end = start + itemsPerPage;
    if (end > filteredPartners.length) end = filteredPartners.length;
    paginatedPartners = filteredPartners.sublist(start, end);
    setState(() {});
  }

  void _nextPage() {
    if (currentPage < totalPages) {
      setState(() { currentPage++; _applyPagination(); });
    }
  }

  void _previousPage() {
    if (currentPage > 1) {
      setState(() { currentPage--; _applyPagination(); });
    }
  }

  void _goToPage(int page) {
    if (page >= 1 && page <= totalPages) {
      setState(() { currentPage = page; _applyPagination(); });
    }
  }

  void _changeItemsPerPage(int? value) {
    if (value != null) {
      setState(() {
        itemsPerPage = value;
        currentPage = 1;
        _applyPagination();
      });
    }
  }

  void _resetFilters() {
    setState(() {
      searchQuery = '';
      filterType = 'Name';
      _searchController.clear();
      currentPage = 1;
      _applyFilters();
    });
  }

  void _exportExcel() {
    final file = excel.Excel.createExcel();
    final sheet = file['My Team'];
    sheet.appendRow(["ID", "Full Name", "Email", "Mobile", "Working Area", "Team Size", "Status", "Created At"]);
    for (var p in filteredPartners) {
      sheet.appendRow([
        p.id,
        p.fullName,
        p.email,
        p.mobile,
        p.workingArea,
        p.teamSize,
        p.status,
        p.createdAt,
      ]);
    }
    final bytes = file.encode();
    if (bytes != null) {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", "my_team.xlsx")
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }

  Future<void> _exportPDF() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Table.fromTextArray(
            headers: ["ID", "Name", "Email", "Mobile", "Working Area", "Team Size", "Status", "Created"],
            data: filteredPartners.map((p) => [
              p.id.toString(),
              p.fullName,
              p.email,
              p.mobile,
              p.workingArea,
              p.teamSize.toString(),
              p.status,
              p.createdAt
            ]).toList(),
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  void _exportDOC() {
    final content = StringBuffer();
    content.writeln("My Team (Referred Partners)\n");
    content.writeln("=" * 50);
    for (var p in filteredPartners) {
      content.writeln("ID: ${p.id}");
      content.writeln("Name: ${p.fullName}");
      content.writeln("Email: ${p.email}");
      content.writeln("Mobile: ${p.mobile}");
      content.writeln("Working Area: ${p.workingArea}");
      content.writeln("Team Size: ${p.teamSize}");
      content.writeln("Status: ${p.status}");
      content.writeln("Created: ${p.createdAt}");
      content.writeln("-" * 30);
    }
    final blob = html.Blob([content.toString()]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "my_team.doc")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  // ==================== APPROVE / REJECT FLOW ====================
  Future<void> _approvePartner(MyReferredPartner partner) async {
    String? email = partner.email;
    final sendOtpResult = await _showSendOtpDialog(email);
    if (sendOtpResult == null) return;
    email = sendOtpResult;
    final verifyResult = await _showVerifyOtpDialog(email!);
    if (verifyResult == null) return;
    final regResult = await _showCompleteRegistrationDialog(email!, partner);
    if (regResult == true) await _loadData();
  }

  Future<String?> _showSendOtpDialog(String initialEmail) async {
    TextEditingController emailCtrl = TextEditingController(text: initialEmail);
    bool loading = false;
    String? error;
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: Colors.white,
              child: Container(
                width: 400,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                      child: const Icon(Icons.mark_email_unread, color: Colors.blue, size: 28),
                    ),
                    const SizedBox(height: 12),
                    const Text("Send OTP", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text("We'll send a one-time password to the email address.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    const SizedBox(height: 20),
                    TextField(
                      controller: emailCtrl,
                      decoration: InputDecoration(
                        labelText: "Email Address",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        errorText: error,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                            child: const Text("Cancel"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: loading ? null : () async {
                              if (emailCtrl.text.trim().isEmpty) {
                                setState(() => error = "Email is required");
                                return;
                              }
                              setState(() => loading = true);
                              try {
                                await _service.sendOtp(emailCtrl.text.trim());
                                if (context.mounted) Navigator.pop(context, emailCtrl.text.trim());
                              } catch (e) {
                                setState(() => error = e.toString());
                              } finally {
                                if (context.mounted) setState(() => loading = false);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4158D0),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text("Send OTP"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<String?> _showVerifyOtpDialog(String email) async {
    TextEditingController otpCtrl = TextEditingController();
    bool loading = false;
    String? error;
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: Colors.white,
              child: Container(
                width: 400,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                      child: const Icon(Icons.verified, color: Colors.green, size: 28),
                    ),
                    const SizedBox(height: 12),
                    const Text("Verify OTP", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text("Enter the 6-digit code sent to $email", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    const SizedBox(height: 20),
                    TextField(
                      controller: otpCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "OTP",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        errorText: error,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                            child: const Text("Cancel"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: loading ? null : () async {
                              if (otpCtrl.text.trim().isEmpty) {
                                setState(() => error = "OTP is required");
                                return;
                              }
                              setState(() => loading = true);
                              try {
                                await _service.verifyOtp(email, otpCtrl.text.trim());
                                if (context.mounted) Navigator.pop(context, otpCtrl.text.trim());
                              } catch (e) {
                                setState(() => error = e.toString());
                              } finally {
                                if (context.mounted) setState(() => loading = false);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4158D0),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text("Verify"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<bool?> _showCompleteRegistrationDialog(String email, MyReferredPartner partner) async {
    TextEditingController usernameCtrl = TextEditingController();
    TextEditingController passwordCtrl = TextEditingController();
    TextEditingController confirmCtrl = TextEditingController();
    bool loading = false;
    String? error;
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: Colors.white,
              child: Container(
                width: 400,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.purple.shade50, shape: BoxShape.circle),
                      child: const Icon(Icons.person_add, color: Colors.purple, size: 28),
                    ),
                    const SizedBox(height: 12),
                    const Text("Complete Registration", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text("Create credentials for ${partner.fullName}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    const SizedBox(height: 20),
                    TextField(
                      controller: usernameCtrl,
                      decoration: InputDecoration(labelText: "Username", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: passwordCtrl,
                      obscureText: true,
                      decoration: InputDecoration(labelText: "Password", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: confirmCtrl,
                      obscureText: true,
                      decoration: InputDecoration(labelText: "Confirm Password", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 6),
                      Text(error!, style: const TextStyle(color: Colors.red, fontSize: 11)),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context, false),
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                            child: const Text("Cancel"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: loading ? null : () async {
                              final username = usernameCtrl.text.trim();
                              final password = passwordCtrl.text.trim();
                              final confirm = confirmCtrl.text.trim();
                              if (username.isEmpty) {
                                setState(() => error = "Username required");
                                return;
                              }
                              if (password.isEmpty) {
                                setState(() => error = "Password required");
                                return;
                              }
                              if (password != confirm) {
                                setState(() => error = "Passwords do not match");
                                return;
                              }
                              setState(() => loading = true);
                              try {
                                final response = await _service.completeRegistration(
                                  email: email,
                                  username: username,
                                  password: password,
                                  role: 'marketing_partner',
                                );
                                if (response.status) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(response.message), backgroundColor: Colors.green),
                                    );
                                    Navigator.pop(context, true);
                                  }
                                } else {
                                  setState(() => error = response.message);
                                }
                              } catch (e) {
                                setState(() => error = e.toString());
                              } finally {
                                if (context.mounted) setState(() => loading = false);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4158D0),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text("Complete"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _rejectPartner(MyReferredPartner partner) async {
    TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.transparent,
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 10))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                      child: const Icon(Icons.cancel, color: Colors.red, size: 28),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Reject Marketing Partner",
                      style: TextStyle(fontSize: 20, fontStyle: FontStyle.normal, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: reasonController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: "Enter rejection reason...",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final reason = reasonController.text.trim();
                          if (reason.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please enter a reason")),
                            );
                            return;
                          }
                          Navigator.pop(context);
                          try {
                            final response = await _service.rejectPartner(partner.id, reason);
                            if (response.status) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(response.message), backgroundColor: Colors.orange),
                              );
                              await _loadData();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(response.message), backgroundColor: Colors.red),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Reject"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileImage(String? url, double size) {
    if (url == null || url.isEmpty) {
      return const Icon(Icons.person, size: 24, color: Colors.white70);
    }
    return GestureDetector(
      onTap: () => _showFullImageDialog(url),
      child: ClipOval(
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(Icons.person, size: size * 0.6, color: Colors.white70),
        ),
      ),
    );
  }

  void _showFullImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text("Profile Picture", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 100),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPartnerDetailsPopup(MyReferredPartner partner) {
    final bool isPending = partner.status.toLowerCase() == 'pending';
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: LayoutBuilder(
          builder: (context, constraints) {
            double dialogWidth = constraints.maxWidth * 0.9;
            if (constraints.maxWidth > 600) dialogWidth = 550;
            if (constraints.maxWidth > 800) dialogWidth = 700;
            return Container(
              width: dialogWidth,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => _showFullImageDialog(partner.profileImage ?? ''),
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(3),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _buildProfileImage(partner.profileImage, 46),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                partner.fullName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                partner.email,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.white70, size: 32),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _buildTopCustomBadge(
                                partner.status,
                                partner.status.toLowerCase() == 'approved'
                                    ? const Color(0xFFE8F5E9)
                                    : (partner.status.toLowerCase() == 'rejected' ? const Color(0xFFFFEBEE) : const Color(0xFFFFF3E0)),
                                partner.status.toLowerCase() == 'approved'
                                    ? Colors.green
                                    : (partner.status.toLowerCase() == 'rejected' ? Colors.red : Colors.orange),
                              ),
                              _buildTopCustomBadge('Active', const Color(0xFFE3F2FD), const Color(0xFF2196F3)),

                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F5F5),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                                ),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.tag, size: 14, color: Colors.grey),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Referral: ${partner.referralCode}',
                                        style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _buildSectionTitleCustom(Icons.person_outline, 'Personal Information'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildInfoContainerCardCustom([
                            _buildDataRowCustom('ID', partner.id.toString()),
                            _buildDataRowCustom('Mobile', partner.mobile),
                            _buildDataRowCustom('Email', partner.email),
                            _buildDataRowCustom('Created At', partner.createdAt.length > 10 ? partner.createdAt.substring(0, 10) : partner.createdAt),
                          ]),
                          const SizedBox(height: 24),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _buildSectionTitleCustom(Icons.work_outline, 'Professional Details'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildInfoContainerCardCustom([
                            _buildDataRowCustom('Working Area', partner.workingArea),
                            _buildDataRowCustom('Profession', partner.profession),
                            _buildDataRowCustom('Experience', partner.experience),
                            _buildDataRowCustom('Team Size', partner.teamSize.toString()),
                          ]),
                          const SizedBox(height: 24),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _buildSectionTitleCustom(Icons.location_on_outlined, 'Location'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildInfoContainerCardCustom([
                            _buildDataRowCustom('State', partner.state),
                            _buildDataRowCustom('District', partner.district),
                            _buildDataRowCustom('Taluka', partner.taluka),
                            _buildDataRowCustom('Village', partner.village),
                            _buildDataRowCustom('Pincode', partner.pincode),
                          ]),
                          const SizedBox(height: 24),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _buildSectionTitleCustom(Icons.business_center_outlined, 'Companies & Promotion'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildInfoContainerCardCustom([
                            _buildDataRowCustom('Platforms', partner.promotionPlatforms.join(", ")),
                            if (partner.referralLink.isNotEmpty)
                              _buildDataRowCustom('Link', partner.referralLink),
                            const SizedBox(height: 10),
                            // 🛠️ फिक्स: इथे Expanded आणि FittedBox वापरल्यामुळे लहान स्क्रीनवर बटण ओव्हरफ्लो होणार नाही.
                            Row(
                              children: [
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: ElevatedButton.icon(
                                        onPressed: () async {
                                          Navigator.pop(context);
                                          await _navigateToPartnerCompanies(partner);
                                        },
                                        icon: const Icon(Icons.business, size: 16, color: Colors.white),
                                        label: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text('View Referred Companies', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                            SizedBox(width: 6),
                                            Icon(Icons.open_in_new, size: 14, color: Colors.white70),
                                          ],
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF6C5CE7),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ),
                  if (isPending)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.15))),
                        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                      ),
                      // 🛠️ फिक्स: Approve आणि Reject बटन्स ३२०px वर फिट बसण्यासाठी Flexible आणि FittedBox चा वापर
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _rejectPartner(partner);
                                },
                                icon: const Icon(Icons.close, size: 14, color: Colors.red),
                                label: const Text(
                                  'Reject',
                                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.red),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _approvePartner(partner);
                                },
                                icon: const Icon(Icons.check, size: 14, color: Colors.white),
                                label: const Text(
                                  'Approve',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopCustomBadge(String text, Color bgColor, Color textColor, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitleCustom(IconData icon, String title) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF4158D0), Color(0xFFC850C0)]),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6C5CE7),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoContainerCardCustom(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildDataRowCustom(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SelectableText(
                value.isEmpty ? '-' : value,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToPartnerCompanies(MyReferredPartner partner) async {
    try {
      final companies = await _service.getPartnerCompanies(partner.id);
      if (!mounted) return;
      setState(() {
        _selectedPartner = partner;
        _selectedPartnerCompanies = companies;
        _showCompaniesView = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load companies: $e")),
      );
    }
  }

  Widget _buildFilterSection(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: isMobile
          ? Column(
        children: [
          Row(
            children: [
              _buildFilterDropdown(),
              const SizedBox(width: 12),
              Expanded(child: _buildSearchField()),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildExportIcons(),
              Row(
                children: [
                  Text("Total: ${filteredPartners.length}"),
                  const SizedBox(width: 8),
                  IconButton(onPressed: _resetFilters, icon: const Icon(Icons.refresh), color: Colors.red),
                ],
              ),
            ],
          ),
        ],
      )
          : Row(
        children: [
          _buildFilterDropdown(),
          const SizedBox(width: 12),
          Expanded(child: _buildSearchField()),
          const SizedBox(width: 12),
          _buildExportIcons(),
          const SizedBox(width: 12),
          Text("Total: ${filteredPartners.length}"),
          IconButton(onPressed: _resetFilters, icon: const Icon(Icons.refresh), color: Colors.red),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
      width: 120,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: filterType,
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6366F1)),
          style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13),
          isExpanded: true,
          onChanged: (String? newValue) {
            setState(() {
              filterType = newValue!;
              currentPage = 1;
              _applyFilters();
            });
          },
          items: ['Name', 'Email', 'Mobile', 'Status']
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: "Search by $filterType...",
          prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF6366F1)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear, size: 16),
            onPressed: () {
              _searchController.clear();
              setState(() {
                searchQuery = '';
                currentPage = 1;
                _applyFilters();
              });
            },
          )
              : null,
        ),
        onChanged: (value) {
          setState(() {
            searchQuery = value;
            currentPage = 1;
            _applyFilters();
          });
        },
      ),
    );
  }

  Widget _buildExportIcons() {
    return Row(
      children: [
        Tooltip(
          message: "Export Excel",
          child: InkWell(
            onTap: _exportExcel,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Image.asset("assets/icon/xls.png", height: 20, width: 20,
                  errorBuilder: (_, __, ___) => const Icon(Icons.table_chart, size: 20)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: "Export PDF",
          child: InkWell(
            onTap: _exportPDF,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Image.asset("assets/icon/pdf.png", height: 20, width: 20,
                  errorBuilder: (_, __, ___) => const Icon(Icons.picture_as_pdf, size: 20)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: "Export DOC",
          child: InkWell(
            onTap: _exportDOC,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Image.asset("assets/icon/doc.png", height: 20, width: 20,
                  errorBuilder: (_, __, ___) => const Icon(Icons.description, size: 20)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tableHeader(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  Widget _tableCell(String text, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        alignment: Alignment.center,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildPagination() {
    if (filteredPartners.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth > 550 ? constraints.maxWidth : 550,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text("Show "),
                      Container(
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: itemsPerPage,
                            icon: const Icon(Icons.arrow_drop_down),
                            items: rowsPerPageOptions.map((e) => DropdownMenuItem(value: e, child: Text(e.toString()))).toList(),
                            onChanged: _changeItemsPerPage,
                          ),
                        ),
                      ),
                      const Text(" entries"),
                      const SizedBox(width: 16),
                      Text(
                        "Showing ${(currentPage - 1) * itemsPerPage + 1} to ${currentPage * itemsPerPage > filteredPartners.length ? filteredPartners.length : currentPage * itemsPerPage} of ${filteredPartners.length}",
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Row(
                    children: [
                      _compactPageButton(icon: Icons.chevron_left, onTap: currentPage > 1 ? _previousPage : null),
                      if (totalPages <= 5)
                        ...List.generate(totalPages, (index) => _compactPageNumber(index + 1))
                      else if (currentPage <= 3) ...[
                        ...List.generate(4, (index) => _compactPageNumber(index + 1)),
                        const Text("..."),
                        _compactPageNumber(totalPages),
                      ] else if (currentPage >= totalPages - 2) ...[
                        _compactPageNumber(1),
                        const Text("..."),
                        ...List.generate(4, (index) => _compactPageNumber(totalPages - 3 + index)),
                      ] else ...[
                        _compactPageNumber(1),
                        const Text("..."),
                        _compactPageNumber(currentPage - 1),
                        _compactPageNumber(currentPage),
                        _compactPageNumber(currentPage + 1),
                        const Text("..."),
                        _compactPageNumber(totalPages),
                      ],
                      _compactPageButton(icon: Icons.chevron_right, onTap: currentPage < totalPages ? _nextPage : null),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _compactPageButton({required IconData icon, required VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(6)),
      child: IconButton(
        icon: Icon(icon, size: 16),
        onPressed: onTap,
        color: onTap != null ? const Color(0xFF6366F1) : Colors.grey,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      ),
    );
  }

  Widget _compactPageNumber(int pageNum) {
    final isSelected = currentPage == pageNum;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: InkWell(
        onTap: () => _goToPage(pageNum),
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          child: Text(
            pageNum.toString(),
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF1E293B),
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showCompaniesView && _selectedPartner != null) {
      return PartnerCompaniesView(
        partnerName: _selectedPartner!.fullName,
        companies: _selectedPartnerCompanies,
        onBack: () {
          setState(() {
            _showCompaniesView = false;
            _selectedPartner = null;
            _selectedPartnerCompanies = [];
          });
        },
      );
    }

    final isMobile = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text("My Team", style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
            ),
          ],
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildFilterSection(isMobile),
            const SizedBox(height: 8),
            Expanded(
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Table(
                        border: TableBorder(
                          horizontalInside: BorderSide(color: Colors.grey.shade300),
                          verticalInside: BorderSide(color: Colors.grey.shade300),
                          top: BorderSide(color: Colors.grey.shade300),
                          bottom: BorderSide(color: Colors.grey.shade300),
                        ),
                        columnWidths: columnWidths,
                        children: [TableRow(children: headerLabels.map((l) => _tableHeader(l)).toList())],
                      ),
                    ),
                  ),
                  Expanded(
                    child: filteredPartners.isEmpty
                        ? const Center(child: Text("No team members found"))
                        : SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Table(
                          border: TableBorder.all(color: Colors.grey.shade300),
                          columnWidths: columnWidths,
                          children: paginatedPartners.map((partner) {
                            final bool isEven = paginatedPartners.indexOf(partner) % 2 == 0;
                            Color statusColor = partner.status == 'approved'
                                ? Colors.green
                                : (partner.status == 'rejected' ? Colors.red : Colors.orange);
                            return TableRow(
                              decoration: BoxDecoration(
                                color: isEven ? Colors.white : const Color(0xFFF8FAFC),
                              ),
                              children: [
                                _tableCell(partner.id.toString(), onTap: () => _showPartnerDetailsPopup(partner)),
                                _tableCell(partner.fullName, onTap: () => _showPartnerDetailsPopup(partner)),
                                GestureDetector(
                                  onTap: () => _showFullImageDialog(partner.profileImage ?? ''),
                                  child: Container(
                                    height: 40,
                                    width: 40,
                                    alignment: Alignment.center,
                                    child: ClipOval(
                                      child: _buildProfileImage(partner.profileImage, 35),
                                    ),
                                  ),
                                ),
                                _tableCell(partner.email, onTap: () => _showPartnerDetailsPopup(partner)),
                                _tableCell(partner.mobile, onTap: () => _showPartnerDetailsPopup(partner)),
                                _tableCell(partner.workingArea, onTap: () => _showPartnerDetailsPopup(partner)),
                                _tableCell(partner.teamSize.toString(), onTap: () => _showPartnerDetailsPopup(partner)),
                                InkWell(
                                  onTap: () => _showPartnerDetailsPopup(partner),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        partner.status,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                _tableCell(partner.createdAt.substring(0, 10), onTap: () => _showPartnerDetailsPopup(partner)),
                                Container(
                                  alignment: Alignment.center,
                                  child: IconButton(
                                    tooltip: "View Details",
                                    icon: const Icon(Icons.visibility_outlined, size: 18, color: Color(0xFF4158D0)),
                                    onPressed: () => _showPartnerDetailsPopup(partner),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _buildPagination(),
          ],
        ),
      ),
    );
  }
}