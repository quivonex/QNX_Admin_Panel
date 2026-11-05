// lib/screens/banner/banner_management_screen.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../api/api_service.dart';
import '../../models/qnx_admin/banner_model.dart';

class BannerManagementScreen extends StatefulWidget {
  const BannerManagementScreen({super.key});

  @override
  State<BannerManagementScreen> createState() => _BannerManagementScreenState();
}

class _BannerManagementScreenState extends State<BannerManagementScreen> {
  static const Color _primary = Color(0xFF4158D0);
  static const Color _secondary = Color(0xFFC850C0);

  final BannerService _bannerService = BannerService();
  final ImagePicker _picker = ImagePicker();

  List<BannerImage> _banners = [];
  bool _isLoadingList = true;
  String? _listError;

  @override
  void initState() {
    super.initState();
    _loadBanners();
  }

  @override
  void dispose() {
    _bannerService.dispose();
    super.dispose();
  }

  // ───────────────────────── Data ─────────────────────────

  Future<void> _loadBanners() async {
    setState(() {
      _isLoadingList = true;
      _listError = null;
    });
    try {
      final response = await _bannerService.getBannerList();
      if (!mounted) return;
      setState(() {
        _banners = response.data;
        _isLoadingList = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingList = false;
        _listError = 'Failed to load banners: $e';
      });
    }
  }

  Future<void> _confirmAndDelete(BannerImage banner) async {
    if (banner.id == null) {
      _showError('Invalid banner');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Banner'),
        content: Text(
            'Are you sure you want to delete "${banner.title ?? 'this banner'}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await _bannerService.deleteImage(banner.id!);
      if (!mounted) return;
      _showSuccess(response.message);
      _loadBanners();
    } catch (e) {
      if (!mounted) return;
      _showError('Delete failed: $e');
    }
  }

  // ───────────────────────── Dialogs ─────────────────────────

  /// Opens the upload / edit form in a popup.
  /// Pass [banner] to open in edit mode.
  Future<void> _openBannerForm({BannerImage? banner}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _BannerFormDialog(
        bannerService: _bannerService,
        picker: _picker,
        banner: banner,
      ),
    );

    if (result == true) {
      _showSuccess(banner == null
          ? 'Banner uploaded successfully!'
          : 'Banner updated successfully!');
      _loadBanners();
    }
  }

  void _showBannerPreview(BannerImage banner) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primary, _secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.image, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        banner.title ?? 'Banner Image',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (banner.imageUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            banner.imageUrl!,
                            width: double.infinity,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Container(
                              height: 200,
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(Icons.broken_image,
                                    size: 50, color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _openBannerForm(banner: banner);
                              },
                              icon: const Icon(Icons.edit, size: 18),
                              label: const Text('Edit'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primary,
                                foregroundColor: Colors.white,
                                padding:
                                const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _confirmAndDelete(banner);
                              },
                              icon: const Icon(Icons.delete, size: 18),
                              label: const Text('Delete'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding:
                                const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────── Snackbars ─────────────────────────

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ───────────────────────── Build ─────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
      isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF0F5FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Banner Management',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loadBanners,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () => _openBannerForm(),
                icon: const Icon(Icons.add_photo_alternate, size: 18),
                label: const Text('Upload Banner'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoadingList) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_listError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.red),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(_listError!, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadBanners,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBanners,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          // ✅ 5 per row on wide screens, scale down on smaller screens
          final crossAxisCount = width < 500
              ? 2
              : width < 800
              ? 3
              : width < 1100
              ? 4
              : 5;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_banners.isEmpty)
                _buildEmptyState(isDark)
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.0, // ✅ Image साठी जागा वाढवण्यासाठी 1.0 केले
                  ),
                  itemCount: _banners.length,
                  itemBuilder: (context, index) =>
                      _buildBannerCard(_banners[index], isDark),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16213E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.image, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No banners uploaded yet',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _openBannerForm(),
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Upload Banner'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerCard(BannerImage banner, bool isDark) {
    return _BannerCardItem(
      banner: banner,
      isDark: isDark,
      primaryColor: _primary,
      onTap: () => _showBannerPreview(banner),
      onEdit: () => _openBannerForm(banner: banner),
      onDelete: () => _confirmAndDelete(banner),
    );
  }
}

// ═════════════════════════════════════════════════════════════
//                    Upload / Edit Form Popup
// ═════════════════════════════════════════════════════════════

class _BannerFormDialog extends StatefulWidget {
  final BannerService bannerService;
  final ImagePicker picker;
  final BannerImage? banner; // null => upload mode

  const _BannerFormDialog({
    required this.bannerService,
    required this.picker,
    this.banner,
  });

  @override
  State<_BannerFormDialog> createState() => _BannerFormDialogState();
}

class _BannerFormDialogState extends State<_BannerFormDialog> {
  static const Color _primary = Color(0xFF4158D0);
  static const Color _secondary = Color(0xFFC850C0);

  final TextEditingController _titleController = TextEditingController();

  // Web
  Uint8List? _webImageBytes;
  String? _webImageName;
  // Mobile
  File? _selectedImage;

  bool _isLoading = false;
  String? _errorMessage;

  bool get _isEdit => widget.banner != null;
  bool get _hasNewImage => _webImageBytes != null || _selectedImage != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _titleController.text = widget.banner!.title ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await widget.picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );
      if (image == null) return;

      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        setState(() {
          _webImageBytes = bytes;
          _webImageName = image.name;
        });
      } else {
        setState(() => _selectedImage = File(image.path));
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to pick image: $e');
    }
  }

  void _clearImage() {
    setState(() {
      _webImageBytes = null;
      _webImageName = null;
      _selectedImage = null;
    });
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();

    if (title.isEmpty) {
      setState(() => _errorMessage = 'Please enter a title');
      return;
    }
    if (!_isEdit && !_hasNewImage) {
      setState(() => _errorMessage = 'Please select an image');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isEdit) {
        await widget.bannerService.updateImage(
          id: widget.banner!.id!,
          title: title,
          imagePath: _selectedImage?.path,
          webImageBytes: _webImageBytes,
          webImageName: _webImageName,
        );
      } else {
        await widget.bannerService.uploadImage(
          title: title,
          imagePath: _selectedImage?.path ?? '',
          webImageBytes: _webImageBytes,
          webImageName: _webImageName,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = '${_isEdit ? 'Update' : 'Upload'} failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF16213E) : Colors.white;
    final borderColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      backgroundColor: cardColor,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 8, 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primary, _secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isEdit ? Icons.edit : Icons.add_photo_alternate,
                    color: Colors.white,
                    size: 26,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEdit ? 'Update Banner' : 'Upload New Banner',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _isEdit
                              ? 'Edit existing banner'
                              : 'Add a new banner image',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed:
                    _isLoading ? null : () => Navigator.pop(context, false),
                  ),
                ],
              ),
            ),

            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Banner Image',
                      style:
                      TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _isLoading ? null : _pickImage,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 170,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1A1A2E)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor, width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: _buildImagePreview(isDark),
                        ),
                      ),
                    ),
                    if (_hasNewImage) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.green[700], size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              kIsWeb
                                  ? (_webImageName ?? 'Image selected')
                                  : 'Image selected',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.green[700]),
                            ),
                          ),
                          TextButton(
                            onPressed: _isLoading ? null : _clearImage,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(40, 24),
                            ),
                            child: const Text('Remove'),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Text(
                      'Banner Title',
                      style:
                      TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _titleController,
                      enabled: !_isLoading,
                      decoration: InputDecoration(
                        hintText: 'Enter banner title',
                        prefixIcon: const Icon(Icons.title, color: _primary),
                        filled: true,
                        fillColor:
                        isDark ? const Color(0xFF1A1A2E) : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                          const BorderSide(color: _primary, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1A1A2E)
                            : const Color(0xFFF0F4FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              color: _primary, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Supports JPG, PNG, AVIF. Recommended size: 1920x1080px',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border:
                          Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error, color: Colors.red[700], size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                    color: Colors.red[700], fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Footer buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_isEdit ? Icons.update : Icons.upload,
                              size: 18),
                          const SizedBox(width: 8),
                          Text(
                            _isEdit ? 'Update' : 'Upload',
                            style: const TextStyle(
                              fontSize: 14,
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
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(bool isDark) {
    final placeholderColor = isDark ? Colors.grey[400] : Colors.grey[600];

    // Newly selected image
    if (_hasNewImage) {
      if (kIsWeb && _webImageBytes != null) {
        return Image.memory(_webImageBytes!,
            fit: BoxFit.contain, width: double.infinity); // ✅ contain केले
      }
      if (_selectedImage != null) {
        return Image.file(_selectedImage!,
            fit: BoxFit.contain, width: double.infinity); // ✅ contain केले
      }
    }

    // Existing image (edit mode)
    final existingUrl = widget.banner?.imageUrl;
    if (_isEdit && existingUrl != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            existingUrl,
            fit: BoxFit.contain, // ✅ contain केले
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey[300],
              child: const Icon(Icons.broken_image,
                  size: 40, color: Colors.grey),
            ),
          ),
          Positioned(
            right: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Tap to change image',
                style: TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
          ),
        ],
      );
    }

    // Empty placeholder
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.cloud_upload, size: 44, color: placeholderColor),
        const SizedBox(height: 8),
        Text(
          'Tap to select image',
          style: TextStyle(color: placeholderColor, fontSize: 13),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════
//              Banner Card (Image on top, Text below)
// ═════════════════════════════════════════════════════════════

class _BannerCardItem extends StatefulWidget {
  final BannerImage banner;
  final bool isDark;
  final Color primaryColor;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BannerCardItem({
    required this.banner,
    required this.isDark,
    required this.primaryColor,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_BannerCardItem> createState() => _BannerCardItemState();
}

class _BannerCardItemState extends State<_BannerCardItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final banner = widget.banner;
    final isDark = widget.isDark;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF16213E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered
                  ? widget.primaryColor.withOpacity(0.6)
                  : (isDark ? Colors.grey[800]! : Colors.grey[200]!),
              width: _isHovered ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? widget.primaryColor.withOpacity(0.25)
                    : Colors.black.withOpacity(0.05),
                blurRadius: _isHovered ? 14 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Image section (Top) ───
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(11),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // ✅ Image पूर्ण दिसण्यासाठी BoxFit.contain आणि पांढरी बॅकग्राउंड
                      Container(
                        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                        child: banner.imageUrl != null
                            ? Image.network(
                          banner.imageUrl!,
                          fit: BoxFit.contain, // ✅ contain केले
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.broken_image,
                                size: 40, color: Colors.grey),
                          ),
                          loadingBuilder: (_, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              ),
                            );
                          },
                        )
                            : Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported,
                              size: 40, color: Colors.grey),
                        ),
                      ),

                      // ─── Hover overlay with Edit + Delete ───
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        opacity: _isHovered ? 1.0 : 0.0,
                        child: IgnorePointer(
                          ignoring: !_isHovered,
                          child: Container(
                            color: Colors.black.withOpacity(0.55),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Edit button
                                  _OverlayActionButton(
                                    icon: Icons.edit,
                                    label: 'Update',
                                    color: widget.primaryColor,
                                    onTap: widget.onEdit,
                                  ),
                                  const SizedBox(width: 8),
                                  // Delete button
                                  _OverlayActionButton(
                                    icon: Icons.delete,
                                    label: 'Delete',
                                    color: Colors.red,
                                    onTap: widget.onDelete,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ─── Text section (Bottom) ───
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF16213E) : Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(11),
                  ),
                ),
                child: Text(
                  banner.title ?? 'Untitled',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverlayActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OverlayActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}