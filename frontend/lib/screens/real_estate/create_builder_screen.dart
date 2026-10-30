// lib/screens/common/create_builder_screen.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../api/realestate_service.dart';
import '../../models/real_estate/builder_model.dart';
import '../../models/real_estate/pdf_extract_model.dart';

class CreateBuilderScreen extends StatefulWidget {
  final PdfBuilder? prefilledBuilder;
  final Uint8List? prefilledLogoBytes;

  const CreateBuilderScreen({
    super.key,
    this.prefilledBuilder,
    this.prefilledLogoBytes,
  });

  @override
  State<CreateBuilderScreen> createState() => _CreateBuilderScreenState();
}

class _CreateBuilderScreenState extends State<CreateBuilderScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  final _nameController = TextEditingController();
  final _shortInfoController = TextEditingController();
  final _websiteController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  // Logo image state
  Uint8List? _logoBytes;
  String? _logoFileName;
  final ImagePicker _imagePicker = ImagePicker();

  bool _isActive = true;
  bool _isLoading = false;
  bool _isDarkMode = false;

  final BuilderService _builderService = BuilderService();

  late AnimationController _cardController;
  late List<Animation<double>> _cardAnimations;

  @override
  void initState() {
    super.initState();
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _cardAnimations = List.generate(2, (i) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _cardController,
          curve: Interval(i * 0.15, 0.6 + i * 0.1, curve: Curves.easeOutBack),
        ),
      );
    });
    _cardController.forward();

    _prefillFromPdf();
  }

  void _prefillFromPdf() {
    final pre = widget.prefilledBuilder;
    if (pre == null) return;

    if (pre.name.isNotEmpty) _nameController.text = pre.name;
    if (pre.shortInfo.isNotEmpty) _shortInfoController.text = pre.shortInfo;
    if (pre.website.isNotEmpty) _websiteController.text = pre.website;
    if (pre.email.isNotEmpty) _emailController.text = pre.email;
    if (pre.phone.isNotEmpty) _phoneController.text = pre.phone;

    if (widget.prefilledLogoBytes != null) {
      _logoBytes = widget.prefilledLogoBytes;
      _logoFileName = 'builder_logo.jpg';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shortInfoController.dispose();
    _websiteController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _builderService.dispose();
    _cardController.dispose();
    super.dispose();
  }

  Color _getIconColor(String label) {
    final Map<String, Color> colors = {
      'Builder': const Color(0xFF6C63FF),
      'Short': const Color(0xFF00BFA5),
      'Logo': const Color(0xFFF39C12),
      'Website': const Color(0xFF1ABC9C),
      'Email': const Color(0xFF3498DB),
      'Phone': const Color(0xFF2ECC71),
      'Status': const Color(0xFFE74C3C),
    };
    for (var entry in colors.entries) {
      if (label.contains(entry.key)) return entry.value;
    }
    return Colors.grey;
  }

  // ==================== LOGO PICKER ====================
  Future<void> _pickLogoImage(ImageSource source) async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
      );

      if (picked == null) return;

      final bytes = await picked.readAsBytes();

      // Max 2 MB check
      if (bytes.length > 2 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image too large. Please choose an image under 2 MB.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      _safeSetState(() {
        _logoBytes = bytes;
        _logoFileName = picked.name;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeLogoImage() {
    _safeSetState(() {
      _logoBytes = null;
      _logoFileName = null;
    });
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF6C63FF)),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickLogoImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF00BFA5)),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickLogoImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ==================== SUBMIT ====================
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    _safeSetState(() => _isLoading = true);

    try {
      final response = await _builderService.createBuilder(
        name: _nameController.text.trim(),
        shortInfo: _shortInfoController.text.trim(),
        logoBytes: _logoBytes,
        logoFileName: _logoFileName,
        website: _websiteController.text.trim().isEmpty
            ? null
            : _websiteController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        isActive: _isActive,
      );

      if (!mounted) return;

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form on success
        _nameController.clear();
        _shortInfoController.clear();
        _websiteController.clear();
        _emailController.clear();
        _phoneController.clear();
        _safeSetState(() {
          _isActive = true;
          _logoBytes = null;
          _logoFileName = null;
        });

        _showSuccessDialog(response);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        _safeSetState(() => _isLoading = false);
      }
    }
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  void _showSuccessDialog(BuilderCreateResponse response) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Builder Created Successfully',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (response.data != null) ...[
                _buildDetailRow('ID', response.data!.id?.toString() ?? 'N/A'),
                _buildDetailRow('Name', response.data!.name),
                _buildDetailRow('Short Info', response.data!.shortInfo),
                if (response.data!.email != null &&
                    response.data!.email!.isNotEmpty)
                  _buildDetailRow('Email', response.data!.email!),
                if (response.data!.phone != null &&
                    response.data!.phone!.isNotEmpty)
                  _buildDetailRow('Phone', response.data!.phone!),
                if (response.data!.website != null &&
                    response.data!.website!.isNotEmpty)
                  _buildDetailRow('Website', response.data!.website!),
                if (response.data!.logo != null &&
                    response.data!.logo!.isNotEmpty)
                  _buildDetailRow('Logo', response.data!.logo!),
                _buildDetailRow(
                    'Status', response.data!.isActive ? 'Active' : 'Inactive'),
                if (response.data!.createdAt != null)
                  _buildDetailRow(
                      'Created At', _formatDate(response.data!.createdAt!)),
              ],
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.green.shade700, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        response.message,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      final date = DateTime.parse(raw);
      return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== BUILD TEXT FIELD ====================
  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool required = true,
    FocusNode? focusNode,
    FocusNode? nextFocusNode,
    TextInputAction? textInputAction,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? customValidator,
  }) {
    final iconColor = _getIconColor(label);
    return TextFormField(
      inputFormatters: inputFormatters,
      validator: customValidator ??
          (required ? (v) => v!.isEmpty ? 'Required' : null : null),
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      focusNode: focusNode,
      textInputAction: textInputAction ??
          (nextFocusNode != null ? TextInputAction.next : TextInputAction.done),
      onFieldSubmitted: nextFocusNode != null
          ? (value) => FocusScope.of(context).requestFocus(nextFocusNode)
          : null,
      style: TextStyle(
        color: _isDarkMode ? Colors.white : Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: _isDarkMode ? Colors.grey[400] : Colors.grey[700],
        ),
        prefixIcon: Container(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: _isDarkMode ? Colors.grey[700]! : Colors.grey.shade200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: iconColor, width: 2),
        ),
        filled: true,
        fillColor: _isDarkMode ? Colors.grey[800] : Colors.grey[50],
        contentPadding:
        const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
    );
  }

  // ==================== LOGO PICKER WIDGET ====================
  Widget _buildLogoPicker() {
    final iconColor = const Color(0xFFF39C12);
    final hasImage = _logoBytes != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.image, color: iconColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'Logo Image',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _isDarkMode ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showImageSourceSheet,
          child: Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.grey[800] : Colors.grey[50],
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasImage
                    ? iconColor
                    : (_isDarkMode ? Colors.grey[700]! : Colors.grey.shade200),
                width: hasImage ? 2 : 1,
              ),
            ),
            child: !hasImage
                ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate_outlined,
                    size: 44, color: iconColor),
                const SizedBox(height: 8),
                Text(
                  'Tap to upload logo',
                  style: TextStyle(
                    color: _isDarkMode
                        ? Colors.grey[300]
                        : Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'PNG, JPG, WEBP up to 2 MB',
                  style: TextStyle(
                    fontSize: 11,
                    color: _isDarkMode
                        ? Colors.grey[500]
                        : Colors.grey[500],
                  ),
                ),
              ],
            )
                : Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      _logoBytes!,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    children: [
                      _circleActionButton(
                        icon: Icons.edit,
                        color: Colors.blue,
                        onTap: _showImageSourceSheet,
                      ),
                      const SizedBox(width: 6),
                      _circleActionButton(
                        icon: Icons.close,
                        color: Colors.red,
                        onTap: _removeLogoImage,
                      ),
                    ],
                  ),
                ),
                if (_logoFileName != null)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _logoFileName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _circleActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: Icon(Icons.edit, color: Colors.white, size: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor:
      _isDarkMode ? const Color(0xFF1A1A2E) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Create Builder',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(
              _isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: _isDarkMode ? Colors.yellow : Colors.grey[600],
            ),
            onPressed: () {
              _safeSetState(() {
                _isDarkMode = !_isDarkMode;
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isMobile ? double.infinity : 800,
              ),
              child: Column(
                children: [
                  // Header Card with Animation
                  ScaleTransition(
                    scale: _cardAnimations[0],
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF6C63FF),
                            Color(0xFF9B59B6),
                            Color(0xFFFF6584)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepPurple.withOpacity(0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
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
                              Icons.business_center,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Builder Registration',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Register a new real estate builder',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Form Card with Animation
                  ScaleTransition(
                    scale: _cardAnimations[1],
                    child: Container(
                      decoration: BoxDecoration(
                        color: _isDarkMode ? const Color(0xFF23233B) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(isMobile ? 16 : 24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Section Title
                              Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6C63FF),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Builder Information',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: _isDarkMode
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              const Divider(height: 1),

                              // Builder Name
                              const SizedBox(height: 20),
                              buildTextField(
                                controller: _nameController,
                                label: 'Builder Name *',
                                icon: Icons.business,
                                required: true,
                                customValidator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Builder name is required';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Short Info
                              buildTextField(
                                controller: _shortInfoController,
                                label: 'Short Info *',
                                icon: Icons.info_outline,
                                maxLines: 2,
                                required: true,
                                customValidator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Short info is required';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Logo Image Picker
                              _buildLogoPicker(),
                              const SizedBox(height: 16),

                              // Website
                              buildTextField(
                                controller: _websiteController,
                                label: 'Website',
                                icon: Icons.public,
                                keyboardType: TextInputType.url,
                                required: false,
                                customValidator: (value) {
                                  if (value != null &&
                                      value.trim().isNotEmpty) {
                                    if (!value.startsWith('http://') &&
                                        !value.startsWith('https://')) {
                                      return 'Please enter a valid URL (e.g., https://example.com)';
                                    }
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Email
                              buildTextField(
                                controller: _emailController,
                                label: 'Email',
                                icon: Icons.email,
                                keyboardType: TextInputType.emailAddress,
                                required: false,
                                customValidator: (value) {
                                  if (value != null &&
                                      value.trim().isNotEmpty) {
                                    if (!value.contains('@') ||
                                        !value.contains('.')) {
                                      return 'Please enter a valid email';
                                    }
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Phone
                              buildTextField(
                                controller: _phoneController,
                                label: 'Phone',
                                icon: Icons.phone,
                                keyboardType: TextInputType.phone,
                                required: false,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(15),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Active Status Card
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: _isDarkMode
                                        ? [
                                      const Color(0xFF2A2A44),
                                      const Color(0xFF23233B),
                                    ]
                                        : [
                                      const Color(0xFFF8FAFC),
                                      const Color(0xFFF1F5F9),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: _isActive
                                            ? Colors.green.withOpacity(0.1)
                                            : Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        _isActive
                                            ? Icons.check_circle
                                            : Icons.cancel,
                                        color: _isActive
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Active Status',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: _isDarkMode
                                                  ? Colors.white70
                                                  : Colors.black87,
                                            ),
                                          ),
                                          Text(
                                            _isActive
                                                ? 'Builder is active and visible'
                                                : 'Builder is inactive',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: _isDarkMode
                                                  ? Colors.grey[500]
                                                  : Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch(
                                      value: _isActive,
                                      onChanged: (value) {
                                        _safeSetState(() {
                                          _isActive = value;
                                        });
                                      },
                                      activeColor: Colors.green,
                                      inactiveThumbColor: Colors.red,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Submit Button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _submitForm,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6C63FF),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    disabledBackgroundColor: Colors.grey[300],
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                      : const Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_circle_outline,
                                          size: 22),
                                      SizedBox(width: 10),
                                      Text(
                                        'CREATE BUILDER',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Info Text
                              Center(
                                child: Text(
                                  'All fields marked with * are required',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _isDarkMode
                                        ? Colors.grey[500]
                                        : Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}