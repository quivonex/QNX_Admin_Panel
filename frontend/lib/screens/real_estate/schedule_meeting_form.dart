// lib/screens/real_estate/schedule_meeting_form.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../api/realestate_service.dart';
import '../../models/real_estate/schedule_meeting_model.dart';

class ScheduleMeetingForm extends StatefulWidget {
  final int? enquiryId; // Optional - can be passed from enquiry list
  final String? customerName;
  final String? propertyTitle;
  final bool isInsideDialog;

  const ScheduleMeetingForm({
    super.key,
    this.enquiryId,
    this.customerName,
    this.propertyTitle,
    this.isInsideDialog = false,
  });

  @override
  State<ScheduleMeetingForm> createState() => _ScheduleMeetingFormState();
}

class _ScheduleMeetingFormState extends State<ScheduleMeetingForm> {
  final _formKey = GlobalKey<FormState>();
  final ScheduleMeetingService _service = ScheduleMeetingService();

  // Controllers
  final TextEditingController _enquiryIdController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _isLoading = false;
  bool _isDarkMode = false;

  // Colors
  static const Color primaryColor = Color(0xFF4158D0);
  static const Color secondaryColor = Color(0xFFC850C0);

  @override
  void initState() {
    super.initState();
    if (widget.enquiryId != null) {
      _enquiryIdController.text = widget.enquiryId.toString();
    }
  }

  @override
  void dispose() {
    _enquiryIdController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    _service.dispose();
    super.dispose();
  }

  // ==================== DATE PICKER ====================
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateController.text =
        "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  // ==================== TIME PICKER ====================
  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _timeController.text =
        "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      });
    }
  }

  // ==================== SUBMIT ====================
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final request = ScheduleMeetingRequest(
        enquiryId: int.parse(_enquiryIdController.text.trim()),
        meetingDate: _dateController.text.trim(),
        meetingTime: _timeController.text.trim(),
        meetingLocation: _locationController.text.trim(),
        meetingNotes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      final response = await _service.scheduleMeeting(request);

      if (mounted) {
        setState(() => _isLoading = false);

        if (response.success) {
          _showSuccessDialog(response);
        } else {
          _showSnackbar(response.message, isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackbar('Failed: ${e.toString()}', isError: true);
      }
    }
  }

  void _showSuccessDialog(ScheduleMeetingResponse response) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Meeting Scheduled!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSuccessRow('Customer', response.meeting?.customer?.name ?? 'N/A'),
            _buildSuccessRow('Property', response.meeting?.property?.title ?? 'N/A'),
            _buildSuccessRow('Date', response.meeting?.meeting?.date ?? 'N/A'),
            _buildSuccessRow('Time', response.meeting?.meeting?.time ?? 'N/A'),
            _buildSuccessRow('Location', response.meeting?.meeting?.location ?? 'N/A'),
            const SizedBox(height: 8),
            if (response.whatsapp?.success == true)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Color(0xFF25D366), size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'WhatsApp notification sent!',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF25D366),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearForm();
            },
            child: const Text('Schedule Another', style: TextStyle(color: primaryColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Done', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _clearForm() {
    _enquiryIdController.clear();
    _dateController.clear();
    _timeController.clear();
    _locationController.clear();
    _notesController.clear();
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      color: _isDarkMode ? const Color(0xFF1A1A2E) : const Color(0xFFF0F5FA),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Card(
              elevation: 4,
              color: _isDarkMode ? const Color(0xFF16213E) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      _buildHeader(),
                      const SizedBox(height: 24),

                      // Optional: Show pre-filled info
                      if (widget.customerName != null || widget.propertyTitle != null)
                        _buildPrefilledInfo(),

                      // Enquiry ID
                      _buildTextField(
                        controller: _enquiryIdController,
                        label: 'Enquiry ID',
                        hint: 'Enter enquiry ID',
                        icon: Icons.confirmation_number_outlined,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Enquiry ID is required';
                          }
                          if (int.tryParse(val.trim()) == null) {
                            return 'Enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Date & Time Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _dateController,
                              label: 'Meeting Date',
                              hint: 'YYYY-MM-DD',
                              icon: Icons.calendar_today_rounded,
                              readOnly: true,
                              onTap: _pickDate,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Date required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: _timeController,
                              label: 'Meeting Time',
                              hint: 'HH:MM',
                              icon: Icons.access_time_rounded,
                              readOnly: true,
                              onTap: _pickTime,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Time required';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Location
                      _buildTextField(
                        controller: _locationController,
                        label: 'Meeting Location',
                        hint: 'Enter meeting location',
                        icon: Icons.location_on_outlined,
                        maxLines: 2,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Location is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Notes (optional)
                      _buildTextField(
                        controller: _notesController,
                        label: 'Meeting Notes (Optional)',
                        hint: 'Any additional notes...',
                        icon: Icons.notes_rounded,
                        maxLines: 3,
                        validator: (val) => null,
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 2,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                              : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_available_rounded, size: 20),
                              SizedBox(width: 10),
                              Text(
                                'Schedule Meeting',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [primaryColor, secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.calendar_month_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Schedule Meeting',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Fill the details to schedule a property visit',
                style: TextStyle(
                  fontSize: 12,
                  color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrefilledInfo() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.customerName != null)
            Row(
              children: [
                const Icon(Icons.person, size: 14, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Customer: ${widget.customerName}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          if (widget.propertyTitle != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.home_work, size: 14, color: primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Property: ${widget.propertyTitle}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    bool readOnly = false,
    VoidCallback? onTap,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: maxLines,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _isDarkMode ? Colors.white : Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(
          fontSize: 13,
          color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
        ),
        hintStyle: TextStyle(
          fontSize: 13,
          color: _isDarkMode ? Colors.grey[600] : Colors.grey[400],
        ),
        prefixIcon: Icon(icon, size: 20, color: primaryColor),
        filled: true,
        fillColor: _isDarkMode ? const Color(0xFF1A1A2E) : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}