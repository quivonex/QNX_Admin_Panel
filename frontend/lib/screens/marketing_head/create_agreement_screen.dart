import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../api/marketing_service.dart';

class CreateAgreementScreen extends StatefulWidget {
  const CreateAgreementScreen({super.key});

  @override
  State<CreateAgreementScreen> createState() => _CreateAgreementScreenState();
}

class _CreateAgreementScreenState extends State<CreateAgreementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _agreementService = AgreementService();
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();

  final _ownerNameController = TextEditingController();
  final _companyAddressController = TextEditingController();
  final _adharController = TextEditingController();
  final _panController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _profitShareController = TextEditingController();
  final _additionalPointsController = TextEditingController();
  final _remarksController = TextEditingController();

  XFile? _headSignatureFile;
  Uint8List? _headSignatureBytes;
  XFile? _headPictureFile;
  Uint8List? _headPictureBytes;

  XFile? _agreementPdfFile;
  String? _agreementPdfFileName;

  bool _isLoading = false;
  bool _isDarkMode = false;

  // ---------- Date picker ----------
  Future<void> _selectDate(TextEditingController controller, {bool isStart = true}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: isStart ? DateTime.now() : DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      controller.text = "${picked.toLocal()}".split(' ')[0];
    }
  }

  // ---------- Image picker ----------
  Future<void> _pickImage(ImageSource source, bool isSignature) async {
    final XFile? picked = await _picker.pickImage(source: source);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        if (isSignature) {
          _headSignatureFile = picked;
          _headSignatureBytes = bytes;
        } else {
          _headPictureFile = picked;
          _headPictureBytes = bytes;
        }
      });
    }
  }

  // ---------- PDF picker ----------
  Future<void> _pickAgreementPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: kIsWeb,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;

    if (kIsWeb) {
      if (file.bytes == null) {
        _showSnackbar('Could not read PDF file. Please try again.', isError: true);
        return;
      }
      setState(() {
        _agreementPdfFile = XFile.fromData(
          file.bytes!,
          name: file.name,
          mimeType: 'application/pdf',
        );
        _agreementPdfFileName = file.name;
      });
    } else {
      if (file.path == null) {
        _showSnackbar('Could not access file path.', isError: true);
        return;
      }
      setState(() {
        _agreementPdfFile = XFile(file.path!);
        _agreementPdfFileName = file.name;
      });
    }
  }

  void _showImagePickerOptions(bool isSignature) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera, isSignature);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery, isSignature);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Reset form and scroll to top ----------
  void _resetForm() {
    // Clear all text controllers
    _ownerNameController.clear();
    _companyAddressController.clear();
    _adharController.clear();
    _panController.clear();
    _startDateController.clear();
    _endDateController.clear();
    _profitShareController.clear();
    _additionalPointsController.clear();
    _remarksController.clear();

    // Clear all file variables
    _headSignatureFile = null;
    _headSignatureBytes = null;
    _headPictureFile = null;
    _headPictureBytes = null;
    _agreementPdfFile = null;
    _agreementPdfFileName = null;

    // Reset form validation state
    _formKey.currentState?.reset();

    // Update UI
    setState(() {});

    // Scroll to top after a tiny delay to let the UI rebuild
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ---------- Submit ----------
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_headSignatureFile == null) {
      _showSnackbar('Please upload Head Signature', isError: true);
      return;
    }
    if (_headPictureFile == null) {
      _showSnackbar('Please upload Head Picture', isError: true);
      return;
    }

    final profitText = _profitShareController.text.trim();
    if (profitText.isEmpty) {
      _showSnackbar('Profit share is required', isError: true);
      return;
    }
    final profitShare = double.tryParse(profitText);
    if (profitShare == null) {
      _showSnackbar('Invalid profit share percentage', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Call API – if it returns without exception, we consider it a success
      final result = await _agreementService.createPartnerHeadAgreement(
        agreementStartDate: _startDateController.text,
        agreementEndDate: _endDateController.text,
        companyOwnerName: _ownerNameController.text,
        companyAddress: _companyAddressController.text,
        ownerAdharNumber: _adharController.text.trim(),
        ownerPanNumber: _panController.text.trim(),
        profitSharePercentage: profitShare,
        additionalPoints: _additionalPointsController.text,
        remarks: _remarksController.text,
        headSignatureImage: _headSignatureFile!,
        headPictureImage: _headPictureFile!,
        agreementPdfFile: _agreementPdfFile,
      );

      if (!mounted) return;

      // ✅ Reset the form immediately after successful API call
      _showSnackbar('Agreement created successfully!');
      _resetForm();
    } catch (e) {
      if (mounted) _showSnackbar('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: _isDarkMode ? const Color(0xFF1A1A2E) : const Color(0xFFF0F5FA),
          child: Center(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                color: _isDarkMode ? const Color(0xFF16213E) : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 30,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Create New Agreement',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: _isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        _buildTextField(
                          controller: _ownerNameController,
                          label: 'Full Name',
                          icon: Icons.person,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _companyAddressController,
                          label: 'Address',
                          icon: Icons.location_on,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _adharController,
                          label: 'Aadhar Number (12 digits)',
                          icon: Icons.credit_card,
                          keyboardType: TextInputType.number,
                          maxLength: 12,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Required';
                            if (value.length != 12) return 'Enter exactly 12 digits';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _panController,
                          label: 'PAN Number (e.g., ABCDE1234F)',
                          icon: Icons.assignment_ind,
                          textCapitalization: TextCapitalization.characters,
                          maxLength: 10,
                          inputFormatters: [
                            UpperCaseTextFormatter(),
                            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Required';
                            final panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$');
                            if (!panRegex.hasMatch(value)) return 'Invalid PAN format';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _startDateController,
                                label: 'Start Date',
                                icon: Icons.calendar_today,
                                readOnly: true,
                                onTap: () => _selectDate(_startDateController, isStart: true),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                controller: _endDateController,
                                label: 'End Date',
                                icon: Icons.calendar_month,
                                readOnly: true,
                                onTap: () => _selectDate(_endDateController, isStart: false),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _profitShareController,
                          label: 'Profit Share Percentage (%)',
                          icon: Icons.percent,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _additionalPointsController,
                          label: 'Additional Points',
                          icon: Icons.note_add,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _remarksController,
                          label: 'Remarks',
                          icon: Icons.comment,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Documents & Signatures',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildImagePickerWithPreview(
                          label: 'Head Signature',
                          file: _headSignatureFile,
                          imageBytes: _headSignatureBytes,
                          onTap: () => _showImagePickerOptions(true),
                          onClear: () => setState(() {
                            _headSignatureFile = null;
                            _headSignatureBytes = null;
                          }),
                        ),
                        const SizedBox(height: 16),
                        _buildImagePickerWithPreview(
                          label: 'Head Picture',
                          file: _headPictureFile,
                          imageBytes: _headPictureBytes,
                          onTap: () => _showImagePickerOptions(false),
                          onClear: () => setState(() {
                            _headPictureFile = null;
                            _headPictureBytes = null;
                          }),
                        ),
                        _buildPdfUploadSection(),
                        const SizedBox(height: 32),
                        Center(
                          child: SizedBox(
                            width: 260,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4158D0),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 2,
                              ),
                              child: const Text(
                                'CREATE AGREEMENT',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_isLoading)
          Positioned.fill(
            child: Material(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPdfUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Agreement PDF (Optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickAgreementPdf,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: _isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
              color: _isDarkMode ? Colors.grey[800] : Colors.grey[50],
            ),
            child: Row(
              children: [
                const Icon(Icons.picture_as_pdf, color: Colors.red, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: _agreementPdfFileName == null
                      ? Text(
                    'Tap to select PDF',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  )
                      : Text(
                    _agreementPdfFileName!,
                    style: TextStyle(
                      fontSize: 13,
                      color: _isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_agreementPdfFileName != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.red),
                    onPressed: () => setState(() {
                      _agreementPdfFile = null;
                      _agreementPdfFileName = null;
                    }),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    VoidCallback? onTap,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.grey[700], fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF4158D0), size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4158D0), width: 1.5),
        ),
        filled: true,
        fillColor: _isDarkMode ? Colors.grey[800] : Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        counterText: "",
      ),
      validator: validator ?? (value) => value == null || value.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildImagePickerWithPreview({
    required String label,
    required XFile? file,
    required Uint8List? imageBytes,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _isDarkMode ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: _isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
              color: _isDarkMode ? Colors.grey[800] : Colors.grey[50],
            ),
            child: file == null
                ? Row(
              children: [
                Icon(Icons.cloud_upload, color: Colors.grey[600], size: 24),
                const SizedBox(width: 12),
                Text(
                  'Tap to upload $label',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            )
                : Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imageBytes != null
                      ? Image.memory(
                    imageBytes,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  )
                      : Container(
                    width: 50,
                    height: 50,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, color: Colors.grey, size: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    file.name,
                    style: TextStyle(
                      fontSize: 12,
                      color: _isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Colors.red),
                  onPressed: onClear,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _ownerNameController.dispose();
    _companyAddressController.dispose();
    _adharController.dispose();
    _panController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _profitShareController.dispose();
    _additionalPointsController.dispose();
    _remarksController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}