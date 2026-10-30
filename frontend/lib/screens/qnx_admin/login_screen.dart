// lib/screens/qnx_admin/login_screen.dart
// lib/screens/qnx_admin/login_screen.dart
// lib/screens/qnx_admin/login_screen.dart
// lib/screens/qnx_admin/login_screen.dart
// lib/screens/qnx_admin/login_screen.dart
// lib/screens/qnx_admin/login_screen.dart
// lib/screens/qnx_admin/login_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:battery_regeneration_system/screens/qnx_admin/dashboard.dart';
import '../../models/qnx_admin/login_model.dart';
import '../../api/api_response.dart';
import '../../api/api_service.dart';
import '../../models/qnx_admin/role_model.dart';
import '../../api/marketing_service.dart';
import '../../models/marketing_head/marketing_profile_model.dart';
import '../marketing_partner/marketing_partner_dashboard.dart';
import '../marketing_head/marketing_head_dashboard.dart';
import '../support/support_dashboard.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../channel_partner/channel_partner_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final emailController = TextEditingController();
  final otpController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool loading = false;
  bool showForgotPassword = false;
  bool otpSent = false;
  bool otpVerified = false;
  bool obscurePassword = true;
  bool obscureNewPassword = true;
  bool obscureConfirmPassword = true;

  List<Role> roles = [];
  Role? selectedRole;
  final RoleService roleService = RoleService();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final LoginService loginService = LoginService();
  final SendOtpService otpService = SendOtpService();
  final VerifyOtpService verifyOtpService = VerifyOtpService();
  final ResetPasswordService resetPasswordService = ResetPasswordService();

  String formatRoleName(String roleName) {
    String formatted = roleName.replaceAll('_', ' ');
    return formatted.toUpperCase();
  }

  @override
  void initState() {
    super.initState();
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
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
    loadRoles();
  }

  void loadRoles() async {
    try {
      List<Role> fetchedRoles = await roleService.fetchRoles();
      setState(() {
        roles = fetchedRoles;
        if (roles.isNotEmpty) {
          selectedRole = roles[0];
        }
      });
    } catch (e) {
      print("Error loading roles: $e");
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    emailController.dispose();
    otpController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void login() async {
    // ✅ Validate username
    if (usernameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter username"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // ✅ Validate password
    if (passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter password"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // ✅ Validate role selection
    if (selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a role"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => loading = true);

    try {
      // ✅ Get FCM Token
      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
        print('📱 FCM Token: $fcmToken');
      } catch (e) {
        print('⚠️ Could not get FCM token: $e');
      }

      // ✅ Create LoginModel with FCM Token
      LoginModel model = LoginModel(
        username: usernameController.text.trim(),
        password: passwordController.text.trim(),
        role: selectedRole!.roleName,
        fcmToken: fcmToken,
      );

      final response = await loginService.login(model);
      final prefs = await SharedPreferences.getInstance();

      // ✅ Store tokens
      await prefs.setString('access_token', response.accessToken);
      await prefs.setString('refresh_token', response.refreshToken);

      // ✅ 🔥 CRITICAL FIX: API मधून role null आल्यास dropdown चा role वापरा
      final String apiRole = (response.user.role ?? '').trim();
      final String selectedRoleValue = selectedRole?.roleName ?? '';
      final String effectiveRole = apiRole.isNotEmpty ? apiRole : selectedRoleValue;

      print('🔍 API Role: "$apiRole"');
      print('🔍 Selected Role: "$selectedRoleValue"');
      print('🔍 Effective Role: "$effectiveRole"');

      // ✅ Store user info with EFFECTIVE role
      await prefs.setString('user_id', response.user.id.toString());
      await prefs.setString('username', response.user.username);
      await prefs.setString('user_role', effectiveRole);
      await prefs.setString('user_email', response.user.email);
      await prefs.setString('user_name', response.user.username);

      if (response.fcmTokenSaved) {
        print('✅ FCM Token saved successfully on server');
      } else {
        print('⚠️ FCM Token was NOT saved on server');
      }

      // ✅ Role specific IDs - effectiveRole वापरा
      final String userRoleLower = effectiveRole.toLowerCase();
      String referralCode = '';
      int? marketingPartnerId;

      // ✅ Marketing profile फक्त marketing roles साठी fetch करा
      if (userRoleLower.contains('marketing partner') ||
          userRoleLower.contains('marketing_partner') ||
          userRoleLower.contains('marketing head') ||
          userRoleLower.contains('marketing_head')) {
        try {
          print('📤 Fetching marketing profile...');
          final profileService = MarketingProfileService();
          final profileResponse = await profileService.getMyProfile();

          if (profileResponse.status && profileResponse.data != null) {
            referralCode = profileResponse.data!.referralCode ?? response.user.id.toString();
            await prefs.setString('referral_code', referralCode);

            if (userRoleLower.contains('marketing partner') ||
                userRoleLower.contains('marketing_partner')) {
              marketingPartnerId = profileResponse.data!.id;
              await prefs.setString('marketing_partner_id', marketingPartnerId.toString());
              await prefs.setString('partner_id', marketingPartnerId.toString());
              print('✅ Marketing Partner ID from Profile: $marketingPartnerId');
              print('✅ Referral Code: $referralCode');
            }
          } else {
            referralCode = response.user.referralCode ?? response.user.id.toString();
            await prefs.setString('referral_code', referralCode);

            if (userRoleLower.contains('marketing partner') ||
                userRoleLower.contains('marketing_partner')) {
              await prefs.setString('marketing_partner_id', response.user.id.toString());
              await prefs.setString('partner_id', response.user.id.toString());
              print('⚠️ Using user_id as fallback: ${response.user.id}');
            }
          }
        } catch (e) {
          print('❌ Failed to get marketing profile: $e');
          referralCode = response.user.referralCode ?? response.user.id.toString();
          await prefs.setString('referral_code', referralCode);

          if (userRoleLower.contains('marketing partner') ||
              userRoleLower.contains('marketing_partner')) {
            await prefs.setString('marketing_partner_id', response.user.id.toString());
            await prefs.setString('partner_id', response.user.id.toString());
            print('⚠️ Using user_id as fallback: ${response.user.id}');
          }
        }
      } else {
        // Channel Partner किंवा इतर roles साठी referral code = user_id
        referralCode = response.user.id.toString();
        await prefs.setString('referral_code', referralCode);
        print('ℹ️ Skipped marketing profile fetch for role: $userRoleLower');
      }

      // ✅ Marketing Head ID
      if (userRoleLower.contains('marketing head') ||
          userRoleLower.contains('marketing_head')) {
        await prefs.setString('head_id', response.user.id.toString());
        print('✅ Marketing Head ID Saved: ${response.user.id}');
      }

      // ✅ Channel Partner ID Save
      if (userRoleLower.contains('channel partner') ||
          userRoleLower.contains('channel_partner') ||
          userRoleLower == 'cp') {
        await prefs.setString('channel_partner_id', response.user.id.toString());
        await prefs.setString('cp_id', response.user.id.toString());
        print('✅ Channel Partner ID Saved: ${response.user.id}');
      }

      // ✅ Debug
      print('=== 🔍 DEBUG: Login Success ===');
      print('User ID: ${response.user.id}');
      print('Username: ${response.user.username}');
      print('Effective Role: "$effectiveRole"');
      print('Stored user_role: "${prefs.getString('user_role')}"');
      print('Stored channel_partner_id: "${prefs.getString('channel_partner_id')}"');

      setState(() => loading = false);

      // 🎯 ROLE-BASED DASHBOARD ROUTING - effectiveRole वापरा
      final String userRole = effectiveRole.trim().toLowerCase();
      print('🔀 Redirecting based on role: "$userRole"');

      Widget dashboard;

      if (userRole.contains('application support') ||
          userRole.contains('support')) {
        dashboard = const SupportDashboard();
      } else if (userRole.contains('admin') ||
          userRole.contains('qnx admin') ||
          userRole.contains('qnx_admin')) {
        dashboard = const DashboardScreen();
      } else if (userRole.contains('marketing head') ||
          userRole.contains('marketing_head')) {
        dashboard = const MarketingHeadDashboard();
      } else if (userRole.contains('marketing partner') ||
          userRole.contains('marketing_partner')) {
        dashboard = const MarketingPartnerDashboard();
      } else if (userRole.contains('channel partner') ||
          userRole.contains('channel_partner') ||
          userRole == 'cp') {
        // ✅ Channel Partner Dashboard
        dashboard = const ChannelPartnerDashboardScreen();
      } else {
        print('⚠️ Unknown role: "$userRole"');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Unknown role: "$effectiveRole"'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => loading = false);
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => dashboard),
        );
      }
    } catch (e) {
      print("❌ Login ERROR: $e");
      setState(() => loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Login Failed: ${e.toString().replaceAll('Exception:', '')}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void sendOtp() async {
    if (emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please enter email address"),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => loading = true);
    try {
      SendOtpModel model = SendOtpModel(email: emailController.text.trim());
      SendOtpResponse response = await otpService.sendOtp(model);
      setState(() {
        loading = false;
        otpSent = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.msg),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to send OTP"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void verifyOtp() async {
    if (otpController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please enter OTP"),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => loading = true);
    try {
      VerifyOtpModel model = VerifyOtpModel(
        email: emailController.text.trim(),
        otp: otpController.text.trim(),
      );
      VerifyOtpResponse response = await verifyOtpService.verifyOtp(model);
      setState(() {
        loading = false;
        otpVerified = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.msg),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Invalid OTP"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void resetPassword() async {
    if (newPasswordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Passwords do not match"),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Password must be at least 6 characters"),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => loading = true);
    try {
      ResetPasswordModel model = ResetPasswordModel(
        email: emailController.text.trim(),
        newPassword: newPasswordController.text.trim(),
        confirmPassword: confirmPasswordController.text.trim(),
      );
      ResetPasswordResponse response =
      await resetPasswordService.resetPassword(model);
      setState(() => loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.msg),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          showForgotPassword = false;
          otpSent = false;
          otpVerified = false;
          emailController.clear();
          otpController.clear();
          newPasswordController.clear();
          confirmPasswordController.clear();
        });
      }
    } catch (e) {
      setState(() => loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Password reset failed"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    VoidCallback? onToggleObscure,
    TextInputType? keyboardType,
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
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
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
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          // Animated Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF4158D0),
                  Color(0xFFC850C0),
                  Color(0xFFFFCC70),
                ],
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.05),
                    Colors.transparent,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // Decorative Circles
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
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
                color: Colors.white.withOpacity(0.1),
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
                color: Colors.white.withOpacity(0.08),
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
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),

          // Main Content
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 450),
                    child: Column(
                      children: [
                        // Logo and Brand
                        Container(
                          padding:
                          const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                child: Image.asset(
                                  "assets/images/favicon.png",
                                  height: 120,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const SizedBox(height: 5),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Login Form Container
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              Text(
                                showForgotPassword
                                    ? (otpVerified
                                    ? "Reset Password"
                                    : (otpSent ? "Verify OTP" : "Forgot Password"))
                                    : "Welcome Back!",
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                showForgotPassword
                                    ? "Please follow the steps to reset your password"
                                    : "Sign in to continue to dashboard",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Form Fields
                              if (!showForgotPassword) ...[
                                buildTextField(
                                  controller: usernameController,
                                  label: "Username",
                                  icon: Icons.person_outline,
                                ),
                                buildTextField(
                                  controller: passwordController,
                                  label: "Password",
                                  icon: Icons.lock_outline,
                                  obscure: obscurePassword,
                                  onToggleObscure: () {
                                    setState(() {
                                      obscurePassword = !obscurePassword;
                                    });
                                  },
                                ),

                                // Dynamic Role Dropdown
                                Container(
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
                                  child: roles.isEmpty
                                      ? const Center(
                                    child: Padding(
                                      padding:
                                      EdgeInsets.symmetric(vertical: 14),
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                      : DropdownButtonFormField<Role>(
                                    value: selectedRole,
                                    decoration: InputDecoration(
                                      labelText: "Select Role",
                                      labelStyle: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14),
                                      prefixIcon: const Icon(
                                          Icons.person_outline,
                                          color: Color(0xFF6366F1),
                                          size: 20),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                        BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 14),
                                    ),
                                    items: roles.map((role) {
                                      String displayName = formatRoleName(role.roleName);
                                      return DropdownMenuItem<Role>(
                                        value: role,
                                        child: Text(displayName),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        selectedRole = value;
                                      });
                                    },
                                    selectedItemBuilder: (BuildContext context) {
                                      return roles.map((Role role) {
                                        return Text(formatRoleName(role.roleName));
                                      }).toList();
                                    },
                                  ),
                                ),

                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      setState(() {
                                        showForgotPassword = true;
                                      });
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFF6366F1),
                                    ),
                                    child: const Text("Forgot Password?"),
                                  ),
                                ),
                              ] else ...[
                                buildTextField(
                                  controller: emailController,
                                  label: "Email Address",
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                if (otpSent && !otpVerified) ...[
                                  const SizedBox(height: 8),
                                  buildTextField(
                                    controller: otpController,
                                    label: "Enter OTP",
                                    icon: Icons.password,
                                    keyboardType: TextInputType.number,
                                  ),
                                ],
                                if (otpVerified) ...[
                                  const SizedBox(height: 8),
                                  buildTextField(
                                    controller: newPasswordController,
                                    label: "New Password",
                                    icon: Icons.lock_outline,
                                    obscure: obscureNewPassword,
                                    onToggleObscure: () {
                                      setState(() {
                                        obscureNewPassword = !obscureNewPassword;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  buildTextField(
                                    controller: confirmPasswordController,
                                    label: "Confirm Password",
                                    icon: Icons.lock_reset,
                                    obscure: obscureConfirmPassword,
                                    onToggleObscure: () {
                                      setState(() {
                                        obscureConfirmPassword =
                                        !obscureConfirmPassword;
                                      });
                                    },
                                  ),
                                ],
                              ],

                              const SizedBox(height: 24),

                              // Action Button
                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: loading
                                      ? null
                                      : showForgotPassword
                                      ? (otpVerified
                                      ? resetPassword
                                      : (otpSent ? verifyOtp : sendOtp))
                                      : login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6366F1),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    disabledBackgroundColor: Colors.grey[300],
                                  ),
                                  child: loading
                                      ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                      : Text(
                                    showForgotPassword
                                        ? (otpVerified
                                        ? "Reset Password"
                                        : (otpSent
                                        ? "Verify OTP"
                                        : "Send OTP"))
                                        : "Sign In",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),

                              // Back Button for Forgot Password
                              if (showForgotPassword) ...[
                                const SizedBox(height: 16),
                                Center(
                                  child: TextButton(
                                    onPressed: () {
                                      setState(() {
                                        showForgotPassword = false;
                                        otpSent = false;
                                        otpVerified = false;
                                        emailController.clear();
                                        otpController.clear();
                                        newPasswordController.clear();
                                        confirmPasswordController.clear();
                                      });
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.grey[600],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.arrow_back, size: 16),
                                        SizedBox(width: 8),
                                        Text("Back to Login"),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Footer
                        Text(
                          "© 2026 QNX Mart. All rights reserved.",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Loading Overlay
          if (loading)
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
                        valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                      ),
                      SizedBox(height: 12),
                      Text(
                        "Please wait...",
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
}
/*
// lib/screens/qnx_admin/login_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:battery_regeneration_system/screens/qnx_admin/dashboard.dart';
import '../../models/login_model.dart';
import '../../api/api_response.dart';
import '../../api/api_service.dart';
import '../../models/role_model.dart';
import '../marketing_partner/marketing_partner_dashboard.dart';
import '../marketing_head/marketing_head_dashboard.dart';
import '../support/support_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final emailController = TextEditingController();
  final otpController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool loading = false;
  bool showForgotPassword = false;
  bool otpSent = false;
  bool otpVerified = false;
  bool obscurePassword = true;
  bool obscureNewPassword = true;
  bool obscureConfirmPassword = true;

  List<Role> roles = [];
  Role? selectedRole;
  final RoleService roleService = RoleService();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final LoginService loginService = LoginService();
  final SendOtpService otpService = SendOtpService();
  final VerifyOtpService verifyOtpService = VerifyOtpService();
  final ResetPasswordService resetPasswordService = ResetPasswordService();

  @override
  void initState() {
    super.initState();
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
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
    loadRoles();
  }

  void loadRoles() async {
    try {
      List<Role> fetchedRoles = await roleService.fetchRoles();
      setState(() {
        roles = fetchedRoles;
        if (roles.isNotEmpty) {
          selectedRole = roles[0];
        }
      });
    } catch (e) {
      print("Error loading roles: $e");
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    emailController.dispose();
    otpController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void login() async {
    // ✅ Validate username
    if (usernameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter username"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // ✅ Validate password
    if (passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter password"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // ✅ Validate role selection
    if (selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a valid role"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => loading = true);

    try {
      LoginModel model = LoginModel(
        username: usernameController.text.trim(),
        password: passwordController.text.trim(),
        role: selectedRole!.roleName,
      );

      final response = await loginService.login(model);

      // ✅ Check if login was successful
      if (response.accessToken.isEmpty || response.user.id == 0) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Invalid username or password"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final prefs = await SharedPreferences.getInstance();

      // Store tokens
      await prefs.setString('access_token', response.accessToken);
      await prefs.setString('refresh_token', response.refreshToken);

      // Store user info
      await prefs.setString('user_id', response.user.id.toString());
      await prefs.setString('username', response.user.username);
      await prefs.setString('user_role', response.user.role);
      await prefs.setString('user_email', response.user.email);
      await prefs.setString('user_name', response.user.username);

      setState(() => loading = false);

      // ✅ ROLE-BASED DASHBOARD ROUTING
      final String userRole = response.user.role.trim().toLowerCase();
      Widget dashboard;

      print("🔍 User Role from API: ${response.user.role}");
      print("🔍 Lowercase Role: $userRole");

      // ✅ Exact role matching with all possible variations
      if (userRole == 'admin' ||
          userRole == 'qnx admin' ||
          userRole == 'administrator') {
        dashboard = const DashboardScreen();
      }
      else if (userRole == 'marketing head' ||
          userRole == 'marketing_head') {
        dashboard = const MarketingHeadDashboard();
      }
      else if (userRole == 'marketing partner' ||
          userRole == 'marketing_partner') {
        dashboard = const MarketingPartnerDashboard();
      }
      else if (userRole == 'support' ||
          userRole == 'support_agent' ||
          userRole == 'support agent' ||
          userRole == 'application support' ||
          userRole == 'application_support') {
        dashboard = const SupportDashboard();
      }
      else {
        // ✅ If role doesn't match any, show error
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Invalid role: ${response.user.role}"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Login successful! Welcome ${response.user.username}"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );

        // ✅ Navigate to appropriate dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => dashboard),
        );
      }
    } catch (e) {
      print("Login ERROR: $e");
      setState(() => loading = false);

      String errorMessage = e.toString().replaceAll('Exception:', '').trim();

      // ✅ Check for specific error messages
      if (errorMessage.toLowerCase().contains('username') ||
          errorMessage.toLowerCase().contains('user')) {
        errorMessage = "Invalid username";
      } else if (errorMessage.toLowerCase().contains('password')) {
        errorMessage = "Invalid password";
      } else if (errorMessage.toLowerCase().contains('role')) {
        errorMessage = "Invalid role selected";
      } else if (errorMessage.isEmpty || errorMessage == '') {
        errorMessage = "Login failed. Please try again.";
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void sendOtp() async {
    if (emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please enter email address"),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => loading = true);
    try {
      SendOtpModel model = SendOtpModel(email: emailController.text.trim());
      SendOtpResponse response = await otpService.sendOtp(model);
      setState(() {
        loading = false;
        otpSent = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.msg),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to send OTP"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void verifyOtp() async {
    if (otpController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please enter OTP"),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => loading = true);
    try {
      VerifyOtpModel model = VerifyOtpModel(
        email: emailController.text.trim(),
        otp: otpController.text.trim(),
      );
      VerifyOtpResponse response = await verifyOtpService.verifyOtp(model);
      setState(() {
        loading = false;
        otpVerified = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.msg),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Invalid OTP"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void resetPassword() async {
    if (newPasswordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Passwords do not match"),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Password must be at least 6 characters"),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => loading = true);
    try {
      ResetPasswordModel model = ResetPasswordModel(
        email: emailController.text.trim(),
        newPassword: newPasswordController.text.trim(),
        confirmPassword: confirmPasswordController.text.trim(),
      );
      ResetPasswordResponse response =
      await resetPasswordService.resetPassword(model);
      setState(() => loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.msg),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          showForgotPassword = false;
          otpSent = false;
          otpVerified = false;
          emailController.clear();
          otpController.clear();
          newPasswordController.clear();
          confirmPasswordController.clear();
        });
      }
    } catch (e) {
      setState(() => loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Password reset failed"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    VoidCallback? onToggleObscure,
    TextInputType? keyboardType,
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
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
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
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          // Animated Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF4158D0),
                  Color(0xFFC850C0),
                  Color(0xFFFFCC70),
                ],
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.05),
                    Colors.transparent,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // Decorative Circles
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
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
                color: Colors.white.withOpacity(0.1),
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
                color: Colors.white.withOpacity(0.08),
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
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),

          // Main Content
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 450),
                    child: Column(
                      children: [
                        // Logo and Brand
                        Container(
                          padding:
                          const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                child: Image.asset(
                                  "assets/images/img_2.png",
                                  height: 120,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const SizedBox(height: 5),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Login Form Container
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              Text(
                                showForgotPassword
                                    ? (otpVerified
                                    ? "Reset Password"
                                    : (otpSent ? "Verify OTP" : "Forgot Password"))
                                    : "Welcome Back!",
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                showForgotPassword
                                    ? "Please follow the steps to reset your password"
                                    : "Sign in to continue to dashboard",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Form Fields
                              if (!showForgotPassword) ...[
                                buildTextField(
                                  controller: usernameController,
                                  label: "Username",
                                  icon: Icons.person_outline,
                                ),
                                buildTextField(
                                  controller: passwordController,
                                  label: "Password",
                                  icon: Icons.lock_outline,
                                  obscure: obscurePassword,
                                  onToggleObscure: () {
                                    setState(() {
                                      obscurePassword = !obscurePassword;
                                    });
                                  },
                                ),

                                // Dynamic Role Dropdown
                                Container(
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
                                  child: roles.isEmpty
                                      ? const Center(
                                    child: Padding(
                                      padding:
                                      EdgeInsets.symmetric(vertical: 14),
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                      : DropdownButtonFormField<Role>(
                                    value: selectedRole,
                                    decoration: InputDecoration(
                                      labelText: "Select Role",
                                      labelStyle: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14),
                                      prefixIcon: const Icon(
                                          Icons.person_outline,
                                          color: Color(0xFF6366F1),
                                          size: 20),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                        BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 14),
                                    ),
                                    items: roles.map((role) {
                                      return DropdownMenuItem<Role>(
                                        value: role,
                                        child: Text(role.roleName),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        selectedRole = value;
                                      });
                                    },
                                  ),
                                ),

                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      setState(() {
                                        showForgotPassword = true;
                                      });
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFF6366F1),
                                    ),
                                    child: const Text("Forgot Password?"),
                                  ),
                                ),
                              ] else ...[
                                buildTextField(
                                  controller: emailController,
                                  label: "Email Address",
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                if (otpSent && !otpVerified) ...[
                                  const SizedBox(height: 8),
                                  buildTextField(
                                    controller: otpController,
                                    label: "Enter OTP",
                                    icon: Icons.password,
                                    keyboardType: TextInputType.number,
                                  ),
                                ],
                                if (otpVerified) ...[
                                  const SizedBox(height: 8),
                                  buildTextField(
                                    controller: newPasswordController,
                                    label: "New Password",
                                    icon: Icons.lock_outline,
                                    obscure: obscureNewPassword,
                                    onToggleObscure: () {
                                      setState(() {
                                        obscureNewPassword = !obscureNewPassword;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  buildTextField(
                                    controller: confirmPasswordController,
                                    label: "Confirm Password",
                                    icon: Icons.lock_reset,
                                    obscure: obscureConfirmPassword,
                                    onToggleObscure: () {
                                      setState(() {
                                        obscureConfirmPassword =
                                        !obscureConfirmPassword;
                                      });
                                    },
                                  ),
                                ],
                              ],

                              const SizedBox(height: 24),

                              // Action Button
                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: loading
                                      ? null
                                      : showForgotPassword
                                      ? (otpVerified
                                      ? resetPassword
                                      : (otpSent ? verifyOtp : sendOtp))
                                      : login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6366F1),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    disabledBackgroundColor: Colors.grey[300],
                                  ),
                                  child: loading
                                      ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                      : Text(
                                    showForgotPassword
                                        ? (otpVerified
                                        ? "Reset Password"
                                        : (otpSent
                                        ? "Verify OTP"
                                        : "Send OTP"))
                                        : "Sign In",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),

                              // Back Button for Forgot Password
                              if (showForgotPassword) ...[
                                const SizedBox(height: 16),
                                Center(
                                  child: TextButton(
                                    onPressed: () {
                                      setState(() {
                                        showForgotPassword = false;
                                        otpSent = false;
                                        otpVerified = false;
                                        emailController.clear();
                                        otpController.clear();
                                        newPasswordController.clear();
                                        confirmPasswordController.clear();
                                      });
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.grey[600],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.arrow_back, size: 16),
                                        SizedBox(width: 8),
                                        Text("Back to Login"),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Footer
                        Text(
                          "© 2026 QNX Mart. All rights reserved.",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Loading Overlay
          if (loading)
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
                        valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                      ),
                      SizedBox(height: 12),
                      Text(
                        "Please wait...",
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
}*/
