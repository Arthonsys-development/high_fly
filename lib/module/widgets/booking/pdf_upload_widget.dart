import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:highfly/data/repository/document_repository.dart';
import '../../../config/constant/app_colors.dart';
import '../../../config/constant/const_assets.dart';
import '../../utils/app_fonts.dart';

class PdfUploadWidget extends StatefulWidget {
  final String label;
  final String? fileName;
  final bool isRequired;
  final Function(String?) onFileSelected;
  final String? placeholderText;
  final String uploadUrl;

  const PdfUploadWidget({
    super.key,
    required this.label,
    this.fileName,
    this.isRequired = false,
    required this.onFileSelected,
    this.placeholderText,
    required this.uploadUrl,
  });

  @override
  State<PdfUploadWidget> createState() => _PdfUploadWidgetState();
}

class _PdfUploadWidgetState extends State<PdfUploadWidget> {
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _uploadStatus;
  String? _selectedFilePath;
  late DocumentRepository _documentRepository;

  @override
  void initState() {
    super.initState();
    _selectedFilePath = widget.fileName;
    _documentRepository = DocumentRepository();
  }

  Future<void> _requestPermission() async {
    // Check current permission status
    var status = await Permission.storage.status;
    
    // If already granted, return
    if (status.isGranted) {
      return;
    }
    
    // For iOS, we need to check different permissions
    if (Platform.isIOS) {
      status = await Permission.photos.status;
      if (status.isGranted) {
        return;
      }
    }
    
    // If permanently denied, open app settings
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return;
    }
    
    // Request permission
    status = await Permission.storage.request();
    
    // For iOS, also request photos permission
    if (Platform.isIOS && !status.isGranted) {
      final photosStatus = await Permission.photos.request();
      if (!photosStatus.isGranted) {
        throw Exception('Storage permission denied');
      }
    }
    
    if (!status.isGranted) {
      throw Exception('Storage permission denied');
    }
  }

  Future<void> _pickAndUploadPdf() async {
    try {
      setState(() {
        _uploadStatus = 'Requesting permissions...';
      });

      // Request storage permission
      await _requestPermission();

      setState(() {
        _uploadStatus = 'Selecting file...';
      });

      // Pick PDF file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: false,
      );

      if (result == null || result.files.isEmpty) {
        setState(() {
          _uploadStatus = 'No file selected';
        });
        return;
      }

      final file = result.files.first;
      
      // Validate file
      if (file.size == 0) {
        setState(() {
          _uploadStatus = 'File is empty';
        });
        return;
      }

      // Check file size (e.g., 10MB limit)
      if (file.size > 10 * 1024 * 1024) {
        setState(() {
          _uploadStatus = 'File size exceeds 10MB limit';
        });
        return;
      }

      // Set selected file path
      setState(() {
        _selectedFilePath = file.path;
        _uploadStatus = 'File selected: ${file.name}';
      });

      // Upload file
      await _uploadFile(file);
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadStatus = 'Error: ${e.toString()}';
      });
      
      // Notify parent widget of error
      widget.onFileSelected(null);
    }
  }

  Future<void> _uploadFile(PlatformFile file) async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadStatus = 'Uploading...';
    });

    try {
      // Upload using document repository
      final result = await _documentRepository.uploadDocument(
        filePath: file.path!,
        fileName: file.name,
      );

      if (result['success']) {
        setState(() {
          _isUploading = false;
          _uploadStatus = 'Upload successful';
        });
        
        // Notify parent widget of successful upload
        widget.onFileSelected(file.path);
      } else {
        throw Exception(result['message'] ?? 'Upload failed');
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadStatus = 'Upload failed: ${e.toString()}';
      });
      
      // Notify parent widget of error
      widget.onFileSelected(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title with required indicator
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.label,
              style: AppFonts.getFont(
                weight: AppFonts.medium,
                fontSize: 14,
                color: Colors.black,
              ),
            ),
            if (widget.isRequired) ...[
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(top: 5.0),
                child: SizedBox(
                  width: 5,
                  height: 5,
                  child: Image.asset(IconsAssets.star, color: Colors.red),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        
        // File upload field
        GestureDetector(
          onTap: _isUploading ? null : _pickAndUploadPdf,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.textFieldBGColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Colors.black26,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedFilePath != null 
                            ? _selectedFilePath!.split('/').last 
                            : (widget.placeholderText ?? 'Upload PDF file'),
                        style: TextStyle(
                          fontSize: 14,
                          color: _selectedFilePath != null 
                              ? const Color(0xFF475569) 
                              : const Color(0xFF6A6A6A),
                        ),
                      ),
                    ),
                    if (_isUploading) ...[
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          value: _uploadProgress,
                        ),
                      ),
                    ] else ...[
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ],
                ),
                if (_uploadStatus != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _uploadStatus!,
                    style: TextStyle(
                      fontSize: 12,
                      color: _uploadStatus!.toLowerCase().contains('error') || 
                              _uploadStatus!.toLowerCase().contains('failed')
                          ? Colors.red
                          : Colors.grey,
                    ),
                  ),
                  if (_isUploading) ...[
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: _uploadProgress,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}