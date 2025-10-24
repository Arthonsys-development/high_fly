import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../config/constant/app_colors.dart';
import '../../../config/constant/const_assets.dart';
import '../../utils/app_fonts.dart';

class FileUploadWidgetNew extends StatefulWidget {
  final String label;
  final String? fileName;
  final bool isRequired;
  final Function(String?) onFileSelected;
  final String? placeholderText;
  final List<String> acceptedFileTypes;

  const FileUploadWidgetNew({
    super.key,
    required this.label,
    this.fileName,
    this.isRequired = false,
    required this.onFileSelected,
    this.placeholderText,
    this.acceptedFileTypes = const ['pdf', 'jpg', 'jpeg', 'png'],
  });

  @override
  State<FileUploadWidgetNew> createState() => _FileUploadWidgetNewState();
}

class _FileUploadWidgetNewState extends State<FileUploadWidgetNew> {
  String? _uploadStatus;
  String? _selectedFilePath;

  @override
  void initState() {
    super.initState();
    _selectedFilePath = widget.fileName;
  }

  Future<void> _requestPermission() async {
    // For Android 13+ (API 33+), we don't need storage permission for file picker
    // File picker uses scoped storage which doesn't require permissions
    if (Platform.isAndroid) {
      // For Android, file_picker doesn't require storage permissions
      // as it uses scoped storage (SAF - Storage Access Framework)
      return;
    }
    
    // For iOS, we need to check photos permission
    if (Platform.isIOS) {
      var status = await Permission.photos.status;
      if (status.isGranted) {
        return;
      }
      
      // If permanently denied, open app settings
      if (status.isPermanentlyDenied) {
        await openAppSettings();
        return;
      }
      
      // Request permission
      status = await Permission.photos.request();
      if (!status.isGranted) {
        throw Exception('Photos permission denied');
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      setState(() {
        _uploadStatus = 'Requesting permissions...';
      });

      // Request storage permission
      await _requestPermission();

      setState(() {
        _uploadStatus = 'Selecting file...';
      });

      // Pick file based on accepted types
      FilePickerResult? result;
      
      if (widget.acceptedFileTypes.contains('pdf') && 
          widget.acceptedFileTypes.length == 1) {
        // Only PDF files
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
          withData: false,
        );
      } else if (widget.acceptedFileTypes.every((type) => 
          ['jpg', 'jpeg', 'png'].contains(type.toLowerCase()))) {
        // Only image files
        result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          withData: false,
        );
      } else {
        // Mixed file types - use custom with all extensions
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: widget.acceptedFileTypes,
          withData: false,
        );
      }

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

      // Validate file extension
      final fileExtension = file.extension?.toLowerCase();
      if (fileExtension != null && 
          !widget.acceptedFileTypes.any((type) => 
              type.toLowerCase() == fileExtension)) {
        setState(() {
          _uploadStatus = 'File type not supported. Accepted: ${widget.acceptedFileTypes.join(', ')}';
        });
        return;
      }

      // Set selected file path and notify parent widget
      setState(() {
        _selectedFilePath = file.path;
        _uploadStatus = 'File selected: ${file.name}';
      });

      // Notify parent widget of file selection (without uploading)
      widget.onFileSelected(file.path);
    } catch (e) {
      setState(() {
        _uploadStatus = 'Error: ${e.toString()}';
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
          onTap: _pickFile,
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
                            : (widget.placeholderText ?? 'Upload file'),
                        style: TextStyle(
                          fontSize: 14,
                          color: _selectedFilePath != null 
                              ? const Color(0xFF475569) 
                              : const Color(0xFF6A6A6A),
                        ),
                      ),
                    ),
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
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
