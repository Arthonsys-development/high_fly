import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:highfly/config/constant/app_colors.dart';
import 'package:highfly/data/models/hold_list_model.dart';
import 'package:highfly/data/models/hold_document_model.dart' as hold_document_model;
import 'package:highfly/data/repository/booking_api_repository.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/holds_provider.dart';
import '../bookings/webview_screen.dart';
// Conditional import for web image widget
import '../visitors/web_image_widget.dart' if (dart.library.io) '../visitors/web_image_widget_stub.dart';

class HoldDocumentManagementScreen extends ConsumerStatefulWidget {
  final HoldListModel hold;

  const HoldDocumentManagementScreen({super.key, required this.hold});

  @override
  ConsumerState<HoldDocumentManagementScreen> createState() => _HoldDocumentManagementScreenState();
}

class _HoldDocumentManagementScreenState extends ConsumerState<HoldDocumentManagementScreen> {
  final BookingApiRepository _repository = BookingApiRepository();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = false;
  bool _isUploading = false;
  late List<hold_document_model.HoldDocument> _documents;
  
  String? _selectedFileType;
  String? _selectedFilePath;
  XFile? _selectedXFile;


  String _detectFileType(String filePath) {
    final fileName = filePath.toLowerCase();
    
    // Try to detect from filename
    if (fileName.contains('pan') || fileName.contains('pan_card')) {
      return 'pan_card';
    } else if (fileName.contains('aadhar') || fileName.contains('aadhaar')) {
      return 'aadhar_card';
    } else if (fileName.contains('bank') || fileName.contains('statement')) {
      return 'bank_statement';
    } else if (fileName.contains('payment') || fileName.contains('proof')) {
      return 'payment_proof';
    }
    
    // Default to 'other' if can't detect
    return 'other';
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return '';
    
    try {
      // Remove timezone suffix if present
      String raw = dateString.trim();
      if (raw.contains('+')) {
        raw = raw.split('+')[0];
      }
      
      // Parse the ISO date string
      DateTime dateTime = DateTime.parse(raw);
      
      // Format as "dd/MM/yyyy at hh:mm a"
      DateFormat dateFormat = DateFormat('dd/MM/yyyy \'at\' hh:mm a');
      return dateFormat.format(dateTime);
    } catch (e) {
      debugPrint('Error formatting date: $e');
      return dateString; // Return original if parsing fails
    }
  }

  @override
  void initState() {
    super.initState();
    _documents = List.from(widget.hold.documents);
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _refreshDocuments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Refresh holds list from provider
      await ref.read(holdsControllerProvider.notifier).loadHolds();
      
      // Find the updated hold in the list
      final holds = ref.read(holdsControllerProvider).holds;
      final updatedHold = holds.firstWhere(
        (h) => h.id == widget.hold.id,
        orElse: () => widget.hold,
      );

      if (mounted) {
        setState(() {
          _documents = List.from(updatedHold.documents);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing documents: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showFileSourceDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select File Source'),
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
      debugPrint('📷 HoldDocumentManagement: Starting camera image pick');
      
      // On iOS, image_picker automatically handles camera permissions
      // Let it request permissions internally, then catch any errors
      XFile? pickedImage;
      try {
        pickedImage = await _imagePicker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
        );
        debugPrint('📷 HoldDocumentManagement: Image picker returned: ${pickedImage != null ? 'image captured' : 'no image'}');
      } catch (e) {
        debugPrint('❌ HoldDocumentManagement: Error opening camera: $e');
        
        // Check if it's a permission error
        final errorString = e.toString().toLowerCase();
        if (errorString.contains('permission') || 
            errorString.contains('camera') ||
            errorString.contains('denied')) {
          
          if (!kIsWeb && mounted) {
            // Check permission status and handle accordingly
            try {
              var status = await Permission.camera.status;
              
              if (status.isPermanentlyDenied) {
                // Permission is permanently denied, offer to open settings
                final shouldOpenSettings = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Camera Permission Required'),
                      content: const Text(
                        'Camera permission is required to take photos. Would you like to open Settings to enable it?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Open Settings'),
                        ),
                      ],
                    );
                  },
                );
                
                if (shouldOpenSettings == true) {
                  await openAppSettings();
                }
              } else if (!status.isGranted) {
                // Try to request permission
                status = await Permission.camera.request();
                if (!status.isGranted) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Camera permission is required to take photos'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                } else {
                  // Permission granted, try again
                  try {
                    pickedImage = await _imagePicker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: 85,
                    );
                  } catch (retryError) {
                    debugPrint('❌ HoldDocumentManagement: Error on retry: $retryError');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Camera access denied'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                    return;
                  }
                }
              }
            } catch (permissionError) {
              debugPrint('❌ HoldDocumentManagement: Error checking permission: $permissionError');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Camera permission is required to take photos'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Camera permission is required to take photos'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
          return;
        } else {
          // Some other error occurred
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Camera access denied'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      final image = pickedImage;
      if (image != null) {
        // Check file size (10MB limit)
        final fileSize = await image.length();
        if (fileSize > 10 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image size exceeds 10MB limit'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        setState(() {
          _selectedFilePath = image.path;
          _selectedXFile = image;
          _selectedFileType = _detectFileType(image.path);
        });
        
        // Upload directly
        if (mounted) {
          await _uploadDocument();
        }
      }
    } catch (e) {
      debugPrint('Error picking image from camera: $e');
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
              const SnackBar(
                content: Text('Image size exceeds 10MB limit'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        setState(() {
          _selectedFilePath = pickedImage.path;
          _selectedXFile = pickedImage;
          _selectedFileType = _detectFileType(pickedImage.path);
        });
        
        // Upload directly
        if (mounted) {
          await _uploadDocument();
        }
      }
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
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

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: kIsWeb, // On web, we need the file data
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.first;
      
      // Validate file
      if (file.size == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File is empty'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Check file size (10MB limit)
      if (file.size > 10 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File size exceeds 10MB limit'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // On web, file.path might be null, so use file.name instead
      final filePath = kIsWeb ? file.name : (file.path ?? file.name);
      
      // On web, validate that we have file bytes
      if (kIsWeb && (file.bytes == null || file.bytes!.isEmpty)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to read file data. Please try selecting the file again.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      setState(() {
        _selectedFilePath = filePath;
        _selectedXFile = null; // file_picker doesn't provide XFile
        _selectedFileType = _detectFileType(filePath);
      });
      
      // Upload directly
      if (mounted) {
        await _uploadDocument(fileBytes: kIsWeb ? file.bytes : null, fileName: file.name);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting file: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _requestPermission() async {
    // Web doesn't require file picker permissions
    if (kIsWeb) {
      return;
    }
    
    // For Android 13+ (API 33+), we don't need storage permission for file picker
    // For iOS, we need to check photos permission
    try {
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
    } catch (e) {
      debugPrint('Permission error: $e');
    }
  }

  Future<void> _uploadDocument({List<int>? fileBytes, String? fileName}) async {
    if (_selectedFilePath == null || _selectedFilePath!.isEmpty) {
      return;
    }

    // Prevent multiple simultaneous uploads
    if (_isUploading) {
      return;
    }

    // Use detected file type or default to 'other'
    final fileType = _selectedFileType ?? 'other';

    setState(() {
      _isUploading = true;
    });

    try {
      await _repository.addHoldDocument(
        holdId: widget.hold.id,
        filePath: _selectedFilePath!,
        filetype: fileType,
        description: null,
        xFile: _selectedXFile,
        fileBytes: fileBytes,
        fileName: fileName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document uploaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reset form
        setState(() {
          _selectedFilePath = null;
          _selectedFileType = null;
          _selectedXFile = null;
        });
        
        // Refresh documents
        await _refreshDocuments();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll(RegExp(r'^Exception: '), '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _deleteDocument(hold_document_model.HoldDocument document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: const Text('Are you sure you want to delete this document?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _repository.deleteHoldDocument(document.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh documents
        await _refreshDocuments();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting document: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openDocument(String url) async {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document URL is not available'),
        ),
      );
      return;
    }

    try {
      final uri = Uri.parse(url);
      
      final isPdf = url.toLowerCase().endsWith('.pdf');
      final isImage = url.toLowerCase().endsWith('.jpg') ||
          url.toLowerCase().endsWith('.jpeg') ||
          url.toLowerCase().endsWith('.png') ||
          url.toLowerCase().endsWith('.gif');
      
      if (kIsWeb) {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } else {
        if (isImage) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => _FullScreenImagePage(imageUrl: url),
            ),
          );
        } else if (isPdf) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WebViewScreen(
                url: url,
                title: 'Document',
              ),
            ),
          );
        } else {
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening document: $e'),
        ),
      );
    }
  }

  void _showAddDocumentDialog() {
    // On web, directly open file picker
    // On mobile, show options dialog (camera/gallery/file picker)
    if (kIsWeb) {
      _pickDocuments();
    } else {
      _showFileSourceDialog();
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          title: const Text("Manage Documents"),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.primaryTextColor),
            onPressed: () => Navigator.of(context).pop(true),
          ),
          backgroundColor: Colors.white,
          titleTextStyle: TextStyle(color: AppColors.primaryTextColor, fontSize: 18, fontWeight: FontWeight.bold),
          iconTheme: IconThemeData(color: AppColors.primaryTextColor),
          centerTitle: true,
          elevation: 1,
          actions: [
            IconButton(
              icon: Icon(Icons.add, color: AppColors.primaryColor),
              onPressed: _showAddDocumentDialog,
              tooltip: 'Add Document',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Documents list
                Expanded(
                  child: _documents.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.description_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No documents uploaded',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(kIsWeb ? 24 : 16),
                          itemCount: _documents.length,
                          itemBuilder: (context, index) {
                            final document = _documents[index];
                            return _buildDocumentCard(document);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildThumbnail(String url, bool isPdf, bool isImage) {
    if (isImage && url.isNotEmpty) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          color: Colors.grey[100],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: kIsWeb
              ? WebImageWidget(
                  imageUrl: url,
                  width: double.infinity,
                  height: double.infinity,
                  borderRadius: 8,
                  fit: BoxFit.cover,
                )
              : Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey[400],
                        size: 24,
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    } else if (isPdf) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          color: Colors.red[50],
        ),
        child: Icon(
          Icons.picture_as_pdf,
          color: Colors.red[700],
          size: 28,
        ),
      );
    } else {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          color: Colors.grey[100],
        ),
        child: Icon(
          Icons.insert_drive_file,
          color: AppColors.primaryColor,
          size: 28,
        ),
      );
    }
  }

  Widget _buildDocumentCard(hold_document_model.HoldDocument document) {
    final isPdf = document.documentUrl.toLowerCase().endsWith('.pdf') ||
        document.filetype.toLowerCase() == 'pdf';
    final isImage = document.documentUrl.toLowerCase().endsWith('.jpg') ||
        document.documentUrl.toLowerCase().endsWith('.jpeg') ||
        document.documentUrl.toLowerCase().endsWith('.png') ||
        document.documentUrl.toLowerCase().endsWith('.gif') ||
        document.filetype.toLowerCase() == 'image';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.grey[50],
      elevation: 1,
      child: ListTile(
        leading: _buildThumbnail(document.documentUrl, isPdf, isImage),
        title: Text(
          document.filetypeDisplay.isNotEmpty
              ? document.filetypeDisplay
              : document.filetype.replaceAll('_', ' ').toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.primaryTextColor,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (document.description.isNotEmpty)
              Text(
                document.description,
                style: TextStyle(color: Colors.grey[700]),
              ),
            Text(
              _formatDate(document.createdAt),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility),
              onPressed: () => _openDocument(document.documentUrl),
              tooltip: 'View',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteDocument(document),
              tooltip: 'Delete',
            ),
          ],
        ),
        onTap: () => _openDocument(document.documentUrl),
      ),
    );
  }
}

// Full screen image viewer page
class _FullScreenImagePage extends StatelessWidget {
  final String imageUrl;

  const _FullScreenImagePage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Image Preview',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: InteractiveViewer(
        minScale: 0.5,
        maxScale: 5.0,
        panEnabled: true,
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: kIsWeb
              ? WebImageWidget(
                  imageUrl: imageUrl,
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  fit: BoxFit.contain,
                )
              : Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.black,
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 60, color: Colors.white70),
                            SizedBox(height: 16),
                            Text(
                              'Failed to load image',
                              style: TextStyle(color: Colors.white70, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.black,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(
                              color: Colors.white70,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Loading image...',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

