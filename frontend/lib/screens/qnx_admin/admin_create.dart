import 'package:flutter/material.dart';
import '../../models/qnx_admin/admin_create_model.dart';
import '../../models/qnx_admin/role_model.dart';
import '../../models/qnx_admin/login_model.dart'; // ← SendOtpModel, VerifyOtpModel are here
import '../../api/api_service.dart' show RegistrationSendOtpService, RegistrationVerifyOtpService, RegisterService, RoleService;
import '../../api/api_response.dart' show RegistrationSendOtpResponse, RegistrationVerifyOtpResponse, RegisterResponse, RegisterModel;
import '../qnx_admin/dashboard.dart';

class AdminCreateScreen extends StatefulWidget {
  const AdminCreateScreen({super.key});

  @override
  State<AdminCreateScreen> createState() => _AdminCreateScreenState();
}

class _AdminCreateScreenState extends State<AdminCreateScreen>
    with SingleTickerProviderStateMixin {
  // Step: 0 = send OTP, 1 = verify OTP, 2 = registration form
  int _step = 0;

  // Controllers
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  // Services
  final RegistrationSendOtpService _sendOtpService = RegistrationSendOtpService();
  final RegistrationVerifyOtpService _verifyOtpService = RegistrationVerifyOtpService();
  final RegisterService _registerService = RegisterService();
  final RoleService _roleService = RoleService();
  // State
  bool _loading = false;
  List<Role> _roles = [];
  int? _selectedRoleId;
  bool _obscurePassword = true;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Form keys
  final _sendOtpFormKey = GlobalKey<FormState>();
  final _verifyOtpFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadRoles();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _animationController.forward();
  }

  Future<void> _loadRoles() async {
    try {
      List<Role> roleList = await _roleService.fetchRoles();
      if (mounted) {
        setState(() => _roles = roleList);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar("Failed to load roles", Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Step 0: Send OTP
  Future<void> _sendOtp() async {
    if (!_sendOtpFormKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      SendOtpModel model = SendOtpModel(email: _emailController.text.trim());
      RegistrationSendOtpResponse response = await _sendOtpService.sendOtp(model);

      setState(() {
        _loading = false;
        _step = 1;
      });

      _showSnackBar(response.message, Colors.green);
    } catch (e) {
      setState(() => _loading = false);
      _showSnackBar("Error: $e", Colors.red);
    }
  }

  // Step 1: Verify OTP
  Future<void> _verifyOtp() async {
    if (!_verifyOtpFormKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      VerifyOtpModel model = VerifyOtpModel(
        email: _emailController.text.trim(),
        otp: _otpController.text.trim(),
      );
      RegistrationVerifyOtpResponse response = await _verifyOtpService.verifyOtp(model);

      setState(() {
        _loading = false;
        _step = 2;
      });

      _showSnackBar(response.message, Colors.green);
    } catch (e) {
      setState(() => _loading = false);
      _showSnackBar("Error: $e", Colors.red);
    }
  }

  // Step 2: Register
  Future<void> _register() async {
    if (!_registerFormKey.currentState!.validate()) return;
    if (_selectedRoleId == null) {
      _showSnackBar("Please select a role", Colors.orange);
      return;
    }

    setState(() => _loading = true);

    try {
      RegisterModel model = RegisterModel(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        role: _selectedRoleId.toString(),
        phoneNumber: _phoneController.text.trim(),
      );

      RegisterResponse response = await _registerService.register(model);

      setState(() => _loading = false);
      _showSnackBar(response.message, Colors.green);

      // After successful registration, navigate to dashboard
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      _showSnackBar("Error: $e", Colors.red);
    }
  }

  // Helper: build text field with validation
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    VoidCallback? onToggleObscure,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        validator: validator ??
                (value) => (value == null || value.trim().isEmpty) ? "$label is required" : null,
        style: const TextStyle(color: Color(0xFF1E293B), fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFF6366F1), size: 20),
          suffixIcon: onToggleObscure != null
              ? IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey[600],
              size: 20,
            ),
            onPressed: onToggleObscure,
          )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;

    return Scaffold(
      body: Stack(
        children: [
          // Background solid color matching dashboard (light mode)
          Container(
            color: const Color(0xFFF0F5FA), // dashboard main background
          ),
          // Decorative circles (bubbles) - keep them
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.withOpacity(0.05), // subtle
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            top: 100,
            left: 50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.withOpacity(0.04),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            right: 80,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.withOpacity(0.04),
              ),
            ),
          ),

          // Main content
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Column(
                      children: [
                        // Logo and title
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Image.asset(
                                "assets/images/img_2.png",
                                height: 120,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(height: 8),
                              const SizedBox(height: 4),
                              Text(
                                _step == 0
                                    ? "Enter your email to start"
                                    : _step == 1
                                    ? "Enter the OTP sent to your email"
                                    : "Fill in your details",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Form container
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: _buildCurrentStepForm(),
                        ),

                        const SizedBox(height: 20),

                        // Footer
                        Text(
                          "© 2026 QNX Mart. All rights reserved.",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Loading overlay
          if (_loading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                      ),
                      SizedBox(height: 12),
                      Text(
                        "Processing...",
                        style: TextStyle(
                          color: Color(0xFF1E293B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepForm() {
    switch (_step) {
      case 0:
        return _buildSendOtpForm();
      case 1:
        return _buildVerifyOtpForm();
      case 2:
        return _buildRegistrationForm();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSendOtpForm() {
    return Form(
      key: _sendOtpFormKey,
      child: Column(
        children: [
          _buildTextField(
            controller: _emailController,
            label: "Email Address",
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) return "Email is required";
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
                return "Enter a valid email";
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _loading ? null : _sendOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                disabledBackgroundColor: Colors.grey[300],
              ),
              child: const Text(
                "Send OTP",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyOtpForm() {
    return Form(
      key: _verifyOtpFormKey,
      child: Column(
        children: [
          Text(
            "OTP sent to ${_emailController.text}",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _otpController,
            label: "OTP",
            icon: Icons.password,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.trim().isEmpty) return "OTP is required";
              if (value.trim().length != 6) return "OTP must be 6 digits";
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _loading ? null : _verifyOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                disabledBackgroundColor: Colors.grey[300],
              ),
              child: const Text(
                "Verify OTP",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              setState(() {
                _step = 0;
                _otpController.clear();
              });
            },
            child: const Text("Back to email"),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationForm() {
    return Form(
      key: _registerFormKey,
      child: Column(
        children: [
          _buildTextField(
            controller: _usernameController,
            label: "Username",
            icon: Icons.person_outline,
          ),
          _buildTextField(
            controller: _nameController,
            label: "Full Name",
            icon: Icons.badge_outlined,
          ),
          _buildTextField(
            controller: _passwordController,
            label: "Password",
            icon: Icons.lock_outline,
            obscure: _obscurePassword,
            onToggleObscure: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
            validator: (value) {
              if (value == null || value.trim().isEmpty) return "Password is required";
              if (value.length < 6) return "Password must be at least 6 characters";
              return null;
            },
          ),
          _buildTextField(
            controller: _phoneController,
            label: "Phone Number",
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.trim().isEmpty) return "Phone number is required";
              if (!RegExp(r'^[0-9]{10}$').hasMatch(value.trim())) return "Enter a valid 10-digit phone number";
              return null;
            },
          ),
          // Role dropdown
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: DropdownButtonFormField<int>(
              value: _selectedRoleId,
              dropdownColor: Colors.white,
              style: const TextStyle(color: Color(0xFF1E293B), fontSize: 15),
              decoration: InputDecoration(
                labelText: "Select Role",
                labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                prefixIcon: const Icon(Icons.admin_panel_settings_outlined, color: Color(0xFF6366F1), size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              items: _roles.map((role) {
                return DropdownMenuItem<int>(
                  value: role.id,
                  child: Text(role.roleName),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedRoleId = value),
              validator: (value) => value == null ? "Please select a role" : null,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _loading ? null : _register,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                disabledBackgroundColor: Colors.grey[300],
              ),
              child: const Text(
                "Register",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _otpController.dispose();
    _usernameController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}