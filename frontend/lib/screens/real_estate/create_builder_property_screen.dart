// lib/screens/real_estate/create_builder_property_screen.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../api/realestate_service.dart';
import '../../models/real_estate/pdf_extract_model.dart';
import '../../models/real_estate/property_model.dart';
import 'create_builder_screen.dart';
import 'create_property_screen.dart';

class CreateBuilderPropertyScreen extends StatefulWidget {
  const CreateBuilderPropertyScreen({super.key});

  @override
  State<CreateBuilderPropertyScreen> createState() =>
      _CreateBuilderPropertyScreenState();
}

class _CreateBuilderPropertyScreenState extends State<CreateBuilderPropertyScreen> {
  // ✅ Default = 'property' — direct property form opens
  String? _selectedForm = 'property';

  final PdfExtractService _pdfService = PdfExtractService();
  bool _isExtracting = false;
  PdfExtractResponse? _extractedData;
  String? _uploadedPdfName;

  final List<MediaFile> _downloadedImages = [];
  final List<MediaFile> _downloadedVideos = [];
  final List<MediaFile> _downloadedDocuments = [];

  // ✅ NEW — forces CreatePropertyScreen to fully rebuild when PDF changes
  Key _formRefreshKey = UniqueKey();

  @override
  void dispose() {
    _pdfService.dispose();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  Future<void> _pickAndExtractPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.bytes == null) {
        _showSnack('Failed to read PDF file', Colors.red);
        return;
      }

      _safeSetState(() {
        _isExtracting = true;
        _uploadedPdfName = file.name;
      });

      final response = await _pdfService.extractPropertyFromPdf(
        pdfBytes: file.bytes!,
        fileName: file.name,
      );

      if (!response.success || response.data == null) {
        _safeSetState(() => _isExtracting = false);
        _showSnack('Failed to extract data from PDF', Colors.red);
        return;
      }

      // Download all images from PDF
      final downloadedImages = <MediaFile>[];
      for (var img in response.images) {
        final bytes = await _pdfService.downloadImage(img.url);
        if (bytes != null) {
          downloadedImages.add(MediaFile(
            name: 'pdf_image_${img.pageNumber}_${img.imageIndex}.jpg',
            bytes: bytes,
            mimeType: 'image/jpeg',
            size: bytes.length,
          ));
        }
      }

      _safeSetState(() {
        _extractedData = response;
        _downloadedImages
          ..clear()
          ..addAll(downloadedImages);
        _downloadedVideos.clear();
        _downloadedDocuments.clear();
        _isExtracting = false;

        // ✅ Force CreatePropertyScreen to rebuild fresh with new data
        _formRefreshKey = UniqueKey();
      });

      _showSnack(
        'PDF extracted! ${downloadedImages.length} images ready.',
        Colors.green,
      );
    } catch (e) {
      _safeSetState(() => _isExtracting = false);
      _showSnack('Error: $e', Colors.red);
    }
  }

  void _clearPdfData() {
    _safeSetState(() {
      _extractedData = null;
      _uploadedPdfName = null;
      _downloadedImages.clear();
      _downloadedVideos.clear();
      _downloadedDocuments.clear();

      // ✅ Also refresh form to clear pre-filled data
      _formRefreshKey = UniqueKey();
    });
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Always show property form directly — no builder option, no switcher
    return Scaffold(
      body: Column(
        children: [
          _buildTopUploadBar(),
          Expanded(
            child: CreatePropertyScreen(
              key: _formRefreshKey, // ✅ Rebuild on PDF change
              prefilledData: _extractedData?.data,
              prefilledImages: List.from(_downloadedImages),
              prefilledVideos: List.from(_downloadedVideos),
              prefilledDocuments: List.from(_downloadedDocuments),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopUploadBar() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.picture_as_pdf, color: Color(0xFF6C63FF), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _uploadedPdfName ?? 'Upload PDF to auto-fill forms',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _uploadedPdfName != null
                        ? const Color(0xFF1E293B)
                        : Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_extractedData != null)
                const Icon(Icons.check_circle, color: Colors.green, size: 18),
              if (_extractedData != null)
                IconButton(
                  onPressed: _clearPdfData,
                  icon: const Icon(Icons.close, color: Colors.red, size: 18),
                  tooltip: 'Clear PDF Data',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
            ],
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _isExtracting ? null : _pickAndExtractPdf,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF6C63FF).withOpacity(0.4),
                  width: 1.2,
                ),
              ),
              child: _isExtracting
                  ? const Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFF6C63FF)),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text('Extracting data from PDF...',
                        style: TextStyle(fontSize: 12)),
                  ),
                ],
              )
                  : const Row(
                children: [
                  Icon(Icons.cloud_upload_outlined,
                      color: Color(0xFF6C63FF), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Click to Upload PDF',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B))),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF6C63FF)),
                ],
              ),
            ),
          ),
          if (_extractedData != null) ...[
            const SizedBox(height: 6),
            Text(
              'Data extracted! ${_downloadedImages.length} images ready.',
              style: const TextStyle(
                  fontSize: 11, color: Colors.green, fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }
}