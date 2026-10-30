// lib/screens/qnx_admin/update_amount_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../api/api_service.dart';
import '../../models/qnx_admin/amount_update_model.dart';

class UpdateAmountScreen extends StatefulWidget {
  const UpdateAmountScreen({super.key});

  @override
  State<UpdateAmountScreen> createState() => _UpdateAmountScreenState();
}

class _UpdateAmountScreenState extends State<UpdateAmountScreen> {
  final TextEditingController _amountController = TextEditingController();
  final AmountUpdateService _amountService = AmountUpdateService();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _amountController.dispose();
    _amountService.dispose();
    super.dispose();
  }

  Future<void> _updateAmount() async {
    final amount = _amountController.text.trim();

    if (amount.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter an amount';
        _successMessage = null;
      });
      return;
    }

    if (double.tryParse(amount) == null) {
      setState(() {
        _errorMessage = 'Please enter a valid number';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final response = await _amountService.updateAmount(amount);

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (response.status) {
            _successMessage = response.message;
            _errorMessage = null;
            _amountController.clear();

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response.message),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
              ),
            );
          } else {
            _errorMessage = response.message;
            _successMessage = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to update amount: ${e.toString()}';
          _successMessage = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        // CHANGE 1: Width reduced from 75% to 55%
        width: MediaQuery.of(context).size.width * 0.55,
        // CHANGE 2: Reduced padding
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // CHANGE 3: Even more compact Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      // CHANGE 4: Smaller icon container
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.currency_rupee,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Update Amount',
                      style: TextStyle(
                        // CHANGE 5: Smaller font
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    // CHANGE 6: Smaller close button
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),

            // CHANGE 7: Reduced spacing
            const SizedBox(height: 12),

            // CHANGE 8: More compact Info Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF16213E) : const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: const Color(0xFF4158D0),
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'New registration fee for companies',
                      style: TextStyle(
                        // CHANGE 9: Smaller text
                        fontSize: 11,
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // CHANGE 10: Reduced spacing
            const SizedBox(height: 12),

            // CHANGE 11: More compact Amount Input
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              style: TextStyle(
                // CHANGE 12: Smaller font
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.currency_rupee,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  size: 18,
                ),
                hintText: 'Enter amount',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF16213E) : const Color(0xFFF5F7FA),
                // CHANGE 13: Reduced padding
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF4158D0),
                    width: 1.5,
                  ),
                ),
                errorText: _errorMessage,
                errorStyle: const TextStyle(fontSize: 11),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Colors.red[400]!,
                    width: 1.5,
                  ),
                ),
              ),
            ),

            if (_successMessage != null) ...[
              // CHANGE 14: Reduced spacing
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green[700],
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // CHANGE 15: Reduced spacing
            const SizedBox(height: 16),

            // CHANGE 16: More compact Action Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      // CHANGE 17: Smaller padding
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      foregroundColor: isDark ? Colors.grey[400] : Colors.grey[600],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: BorderSide(
                          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateAmount,
                    style: ElevatedButton.styleFrom(
                      // CHANGE 18: Smaller padding and height
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      backgroundColor: const Color(0xFF4158D0),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      elevation: 0,
                      minimumSize: const Size(0, 36),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Text(
                      'Update',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // CHANGE 19: Reduced spacing
            const SizedBox(height: 4),

            // CHANGE 20: More compact Footer
            Center(
              child: Text(
                'Applies to all new company registrations',
                style: TextStyle(
                  fontSize: 9,
                  color: isDark ? Colors.grey[600] : Colors.grey[500],
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}