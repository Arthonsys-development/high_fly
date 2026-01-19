import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform, debugPrint;
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../config/constant/app_colors.dart';
import '../../../config/constant/const_assets.dart';
import 'header_icon_widget.dart';
import 'action_buttons.dart';

class DocumentFileData {
  final String path;
  final String name;
  final List<int>? bytes;

  DocumentFileData({
    required this.path,
    required this.name,
    this.bytes,
  });
}

class UploadDocumentsSection extends StatefulWidget {
  final String title;
  final String nextButtonText;
  final VoidCallback? onPrevious;
  final Function(List<String>)? onNext;
  final Function(List<DocumentFileData>)? onNextWithData; // New callback for passing file data
  final List<String>? initialDocuments;

  const UploadDocumentsSection({
    super.key,
    required this.title,
    required this.nextButtonText,
    this.onPrevious,
    this.onNext,
    this.onNextWithData,
    this.initialDocuments,
  });

  @override
  State<UploadDocumentsSection> createState() => _UploadDocumentsSectionState();
}

class _UploadDocumentsSectionState extends State<UploadDocumentsSection> {
  List<String> _documentPaths = [];
  List<DocumentFileData> _documentFiles = []; // Store file data for web
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.initialDocuments != null) {
      _documentPaths = List<String>.from(widget.initialDocuments!);
    }
  }

  Future<void> _requestPermission() async {
    // Web doesn't require file picker permissions
    if (kIsWeb) {
      return;
    }
    
    // For Android 13+ (API 33+), we don't need storage permission for file picker
    if (defaultTargetPlatform == TargetPlatform.android) {
      return;
    }
    
    // For iOS, we need to check photos permission
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      var status = await Permission.photos.status;
      if (status.isGranted) {
        return;
      }
      
      if (status.isPermanentlyDenied) {
        await openAppSettings();
        return;
      }
      
      status = await Permission.photos.request();
      if (!status.isGranted) {
        throw Exception('Photos permission denied');
      }
    }
  }

  /// Show upload source selection dialog
  Future<void> _showUploadSourceDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Upload Document'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Camera option - only show on mobile platforms
              if (!kIsWeb)
                ListTile(
                  leading: Icon(Icons.camera_alt, color: AppColors.primaryColor),
                  title: const Text('Take Photo'),
                  subtitle: const Text('Capture image from camera'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Future.microtask(() => _pickImageFromCamera());
                  },
                ),
              // Gallery option
              ListTile(
                leading: Icon(Icons.photo_library, color: AppColors.primaryColor),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Select image from gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  Future.microtask(() => _pickImageFromGallery());
                },
              ),
              // Document upload option
              ListTile(
                leading: Icon(Icons.upload_file, color: AppColors.primaryColor),
                title: const Text('Upload Document'),
                subtitle: const Text('Select PDF or other documents'),
                onTap: () {
                  Navigator.of(context).pop();
                  Future.microtask(() => _pickDocuments());
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Pick image from camera
  Future<void> _pickImageFromCamera() async {
    try {
      // Check and request camera permission on mobile
      if (!kIsWeb) {
        try {
          final status = await Permission.camera.request();
          if (!status.isGranted) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Camera permission is required to take photos'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
            return;
          }
        } catch (permissionError) {
          debugPrint('Error requesting camera permission: $permissionError');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error requesting camera permission: $permissionError'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      final XFile? pickedImage = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (pickedImage != null) {
        // Check file size (10MB limit)
        final fileSize = await pickedImage.length();
        if (fileSize > 10 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Image size exceeds 10MB limit'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 2),
              ),
            );
          }
          return;
        }

        // Read bytes on web
        List<int>? bytes;
        if (kIsWeb) {
          bytes = await pickedImage.readAsBytes();
          debugPrint('📷 UploadDocumentsSection: Camera image selected, bytes: ${bytes.length}');
        }

        setState(() {
          _documentPaths.add(pickedImage.path);
          _documentFiles.add(DocumentFileData(
            path: pickedImage.path,
            name: pickedImage.name.isNotEmpty ? pickedImage.name : pickedImage.path.split('/').last,
            bytes: bytes,
          ));
        });
      }
    } catch (e) {
      debugPrint('❌ Error picking image from camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image from camera: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Pick image from gallery
  Future<void> _pickImageFromGallery() async {
    try {
      // Request gallery permission
      await _requestPermission();

      final XFile? pickedImage = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedImage != null) {
        // Check file size (10MB limit)
        final fileSize = await pickedImage.length();
        if (fileSize > 10 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Image size exceeds 10MB limit'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 2),
              ),
            );
          }
          return;
        }

        // Read bytes on web
        List<int>? bytes;
        if (kIsWeb) {
          bytes = await pickedImage.readAsBytes();
          debugPrint('🖼️ UploadDocumentsSection: Gallery image selected, bytes: ${bytes.length}');
        }

        setState(() {
          _documentPaths.add(pickedImage.path);
          _documentFiles.add(DocumentFileData(
            path: pickedImage.path,
            name: pickedImage.name.isNotEmpty ? pickedImage.name : pickedImage.path.split('/').last,
            bytes: bytes,
          ));
        });
      }
    } catch (e) {
      debugPrint('❌ Error picking image from gallery: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image from gallery: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Pick documents (PDF and other files)
  Future<void> _pickDocuments() async {
    try {
      await _requestPermission();

      // Pick multiple files - allow PDF, images
      // On web, we need file data (bytes) for upload
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: true,
        withData: kIsWeb, // Read file bytes on web
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      // Validate and add files
      final List<String> validFiles = [];
      final List<DocumentFileData> validFileData = [];
      for (var file in result.files) {
        // Validate file
        if (file.size == 0) {
          continue;
        }

        // Check file size (10MB limit)
        if (file.size > 10 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('File ${file.name} exceeds 10MB limit and was skipped'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 2),
              ),
            );
          }
          continue;
        }

        // Validate file extension
        final fileExtension = file.extension?.toLowerCase();
        if (fileExtension != null && 
            !['pdf', 'jpg', 'jpeg', 'png'].contains(fileExtension)) {
          continue;
        }

        // On web, file.path might be null, so use file.name instead
        final filePath = kIsWeb ? file.name : (file.path ?? file.name);
        validFiles.add(filePath);
        
        // Store file data for web (bytes + name)
        final fileBytes = kIsWeb ? file.bytes : null;
        debugPrint('📁 UploadDocumentsSection: Selected file ${file.name}, bytes: ${fileBytes?.length ?? 0}');
        
        validFileData.add(DocumentFileData(
          path: filePath,
          name: file.name,
          bytes: fileBytes,
        ));
      }

      if (validFiles.isNotEmpty) {
        setState(() {
          _documentPaths.addAll(validFiles);
          _documentFiles.addAll(validFileData);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting files: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeDocument(int index) {
    setState(() {
      _documentPaths.removeAt(index);
      if (index < _documentFiles.length) {
        _documentFiles.removeAt(index);
      }
    });
  }

  String _getFileName(String path) {
    return path.split('/').last;
  }

  @override
  Widget build(BuildContext context) {
    final largeSpacing = kIsWeb ? 40.0 : 40.0;
    
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: kIsWeb ? 20 : 20,
        bottom: kIsWeb ? 20 : 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header with icon
          HeaderIconWidget(
            icon: IconsAssets.cardIcon, // Using card icon as placeholder, you can replace with document icon if available
            title: 'Upload Documents',
            subtitle: 'Upload multiple documents',
          ),
          
          SizedBox(height: largeSpacing),
          
          // Web: Clean form layout with max width, Mobile: Stacked layout
          if (kIsWeb)
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                width: double.infinity,
                child: _buildUploadArea(),
              ),
            )
          else
            _buildUploadArea(),
          
          SizedBox(height: largeSpacing),
          
          // Action buttons
          ActionButtons(
            onPrevious: widget.onPrevious,
            onNext: () {
              debugPrint('🔘 UploadDocumentsSection: Next button clicked. isWeb: $kIsWeb, files: ${_documentFiles.length}, paths: ${_documentPaths.length}');
              // Pass file data if callback supports it (for web uploads)
              if (kIsWeb && widget.onNextWithData != null && _documentFiles.isNotEmpty) {
                debugPrint('📤 UploadDocumentsSection: Calling onNextWithData with ${_documentFiles.length} files');
                widget.onNextWithData?.call(_documentFiles);
              } else if (widget.onNext != null) {
                debugPrint('📤 UploadDocumentsSection: Calling onNext with ${_documentPaths.length} paths');
                widget.onNext?.call(_documentPaths);
              } else {
                debugPrint('⚠️ UploadDocumentsSection: No callback available!');
              }
            },
            isPreviousEnabled: widget.onPrevious != null,
            nextButtonText: widget.nextButtonText,
          ),
          
          SizedBox(height: kIsWeb ? 20 : 20),
        ],
      ),
    );
  }

  Widget _buildUploadArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Upload button
        GestureDetector(
          onTap: _showUploadSourceDialog,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: AppColors.textFieldBGColor,
              borderRadius: BorderRadius.circular(kIsWeb ? 8 : 6),
              border: Border.all(
                color: Colors.black26,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Upload Documents',
                  style: TextStyle(
                    fontSize: kIsWeb ? 16 : 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.headingTextColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Info text
        Text(
          'Upload Aadhar Card, Pan Card, Form 16A, Bank Statement, etc. You can upload multiple documents (PDF, JPG, JPEG, PNG). Maximum file size: 10MB per file.',
          style: TextStyle(
            fontSize: kIsWeb ? 14 : 12,
            color: AppColors.darkGreyColor,
          ),
        ),
        
        // List of uploaded documents
        if (_documentPaths.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Uploaded Documents (${_documentPaths.length})',
            style: TextStyle(
              fontSize: kIsWeb ? 16 : 14,
              fontWeight: FontWeight.w600,
              color: AppColors.headingTextColor,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(_documentPaths.length, (index) {
            return _buildDocumentItem(_documentPaths[index], index);
          }),
        ],
      ],
    );
  }

  Widget _buildDocumentItem(String filePath, int index) {
    final fileName = _getFileName(filePath);
    final isPDF = fileName.toLowerCase().endsWith('.pdf');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kIsWeb ? 8 : 6),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isPDF 
                  ? Colors.red.withOpacity(0.1)
                  : AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              isPDF ? Icons.picture_as_pdf : Icons.image,
              color: isPDF ? Colors.red : AppColors.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: TextStyle(
                    fontSize: kIsWeb ? 14 : 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.headingTextColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Document ${index + 1}',
                  style: TextStyle(
                    fontSize: kIsWeb ? 12 : 11,
                    color: AppColors.darkGreyColor,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _removeDocument(index),
            tooltip: 'Remove document',
          ),
        ],
      ),
    );
  }
}

