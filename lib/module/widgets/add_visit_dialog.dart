import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:highfly/config/constant/app_colors.dart';
import 'package:highfly/config/constant/const_assets.dart';
import 'package:highfly/data/models/response_model/project_response_model.dart';
import 'package:highfly/data/models/request_models/visit_request_model.dart';
import 'package:highfly/data/repository/auth_api_repository.dart';
import 'package:highfly/module/global/widgets/custom_button.dart';
import 'package:highfly/module/utils/location_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' show File;
import 'dart:typed_data' show Uint8List;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import 'package:geolocator/geolocator.dart';

import '../../config/constant/app_strings.dart';
import '../../config/routes.dart';
import '../global/widgets/common_app_bar.dart';

class AddVisitDialog extends StatefulWidget {
  final Project project;
  
  const AddVisitDialog({super.key, required this.project});

  @override
  State<AddVisitDialog> createState() => _AddVisitDialogState();
}

class _AddVisitDialogState extends State<AddVisitDialog>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  final LocationService _locationService = LocationService();
  XFile? _pickedImage;
  Uint8List? _webImage;

  final TextEditingController _visitorNameController = TextEditingController();
  final TextEditingController _reraNUmberController = TextEditingController();
  final TextEditingController _teamLeaderNameController = TextEditingController();
  final TextEditingController _commentsController = TextEditingController();

  // String? visitorName;
  // String? reraNUmber;
  // String? teamLeaderName;
  String? selectedAgent;
  // String? comments;
  String? phoneNumber;
  String? email;
  bool _isSaving = false;
  String _currentLatitude = '';
  String _currentLongitude = '';
  bool _isInBackground = false;
  bool _isPickingImage = false;
  DateTime? _imagePickStartTime;

  final List<String> agents = ["Sarah Johnson", "Michael Smith", "Emily Brown"];

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    debugPrint("Project Name: ${widget.project.name}");
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.paused) {
      // App is going to background (camera opened)
      debugPrint('App going to background, isPickingImage: $_isPickingImage');
      setState(() {
        _isInBackground = true;
      });
    } else if (state == AppLifecycleState.resumed) {
      // App is coming back from background
      debugPrint('App resuming from background, isPickingImage: $_isPickingImage');
      
      // If we were picking an image recently, give it time to complete
      if (_isPickingImage && _imagePickStartTime != null) {
        final timeSincePickStart = DateTime.now().difference(_imagePickStartTime!).inMilliseconds;
        debugPrint('Time since image pick start: $timeSincePickStart ms');
        
        // If it's been less than 3 seconds since we started picking, wait a bit more
        if (timeSincePickStart < 3000) {
          debugPrint('App resumed during image picking, delaying navigation check');
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (mounted) {
              setState(() {
                _isInBackground = false;
              });
            }
          });
          return;
        }
      }
      
      setState(() {
        _isInBackground = false;
      });
      
      // If we were picking an image, reset the flag after a short delay
      if (_isPickingImage) {
        debugPrint('App resumed while picking image, resetting flag');
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            setState(() {
              _isPickingImage = false;
              _imagePickStartTime = null;
            });
            // Also reset the global flag
            debugPrint('Resetting global isPickingImage flag');
            Routes.isPickingImage = false;
          }
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _visitorNameController.dispose();
    _reraNUmberController.dispose();
    _teamLeaderNameController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('AddVisitDialog build called, isPickingImage: $_isPickingImage, isInBackground: $_isInBackground');
    return WillPopScope(
      onWillPop: () async {
        // If we're picking an image, prevent back navigation
        if (_isPickingImage) {
          debugPrint('Preventing back navigation during image picking');
          return false;
        }
        return true;
      },
      child: /*Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: */Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60), 
        child: commonAppBar(
          context, 
          "Add Visit",
          onBack: () {
            // If we're picking an image, prevent back navigation
            if (_isPickingImage) {
              debugPrint('Preventing back navigation during image picking');
              return;
            }
            Navigator.of(context).pop();
          },
        ),
      ),
      body: GestureDetector(
        onTap: (){
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      // Row(
                      //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //   children: [
                      //     Text(
                      //       "Add Visit",
                      //       style: TextStyle(
                      //         fontSize: 18,
                      //         color: AppColors.primaryTextColor,
                      //         fontWeight: FontWeight.bold,
                      //       ),
                      //     ),
                      //     IconButton(
                      //       icon: const Icon(Icons.close, size: 20),
                      //       onPressed: () => Navigator.pop(context),
                      //     ),
                      //   ],
                      // ),
                      // const SizedBox(height: 2),
                      // Divider(color: AppColors.secondaryTextColor, height: 0.2),
                      const SizedBox(height: 16),

                      _buildCustomTextField(
                        label: "Visitor Name",
                        txtController: _visitorNameController,
                        isRequired: true,
                        // onChanged: (value) => visitorName = value,
                        validator: (value) => value == null || value.isEmpty ? "Enter visitor name" : null,
                      ),

                      const SizedBox(height: 12),

                      _buildCustomTextField(
                        label: "RERA Number",
                        txtController: _reraNUmberController,
                        isRequired: true,
                        // onChanged: (value) => reraNUmber = value,
                        validator: (value) => value == null || value.isEmpty ? "Enter your RERA number" : null,
                      ),

                      const SizedBox(height: 12),

                      _buildCustomTextField(
                        label: "Team Leader Name",
                        txtController: _teamLeaderNameController,
                        isRequired: true,
                        // onChanged: (value) => teamLeaderName = value,
                        validator: (value) => value == null || value.isEmpty ? "Enter team leader name" : null,
                      ),


                      const SizedBox(height: 12),

                      // _buildCustomDropdown(
                      //   label: "Assign Agent *",
                      //   value: selectedAgent,
                      //   items: agents,
                      //   onChanged: (value) {
                      //     setState(() {
                      //       selectedAgent = value;
                      //     });
                      //   },
                      //   validator: (value) => value == null ? "Please select an agent" : null,
                      // ),
                      // const SizedBox(height: 12),

                      _buildVisitorPhotoSection(),
                      const SizedBox(height: 12),

                      _buildCustomTextField(
                        label: "Comments",
                        txtController: _commentsController,
                        maxLines: 3,
                        // onChanged: (value) => comments = value,
                      ),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 40,
                              child: OutlinedButton(
                                style: ButtonStyle(
                                  side: WidgetStateProperty.all(
                                    BorderSide(color: AppColors.primaryTextColor),
                                  ),

                                ),
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Cancel", style: TextStyle(color: AppColors.primaryTextColor),),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: CustomButton(
                              height: 40,
                              text: _isSaving ? "Saving..." : "Save Visit",
                              onPressed: _isSaving ? null : _saveVisit,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // ),
              ),
        ),
      ),
    );
  }

  Widget _buildVisitorPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Visitor Photo",
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 4),
            Image.asset(
              IconsAssets.star,
              width: 8,
              height: 8,
              color: Colors.red,
            ),
          ],
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _showImageSourceDialog,
          child: Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.secondaryTextColor),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[100],
            ),
            child: _pickedImage != null || _webImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: kIsWeb 
                        ? (_webImage != null
                            ? Image.memory(
                                _webImage!,
                                fit: BoxFit.cover,
                                width: 100,
                                height: 100,
                              )
                            : Container())
                        : (_pickedImage != null
                            ? Image.file(
                                File(_pickedImage!.path),
                                fit: BoxFit.cover,
                                width: 100,
                                height: 100,
                              )
                            : Container()),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        color: AppColors.secondaryTextColor,
                        size: 30,
                      ),
                      Text(
                        "Tap to upload",
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  /// Show image source selection dialog
  Future<void> _showImageSourceDialog() async {
    debugPrint('Showing image source dialog');
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt, color: AppColors.primaryColor),
                title: const Text('Camera'),
                onTap: () {
                  debugPrint('Camera selected, setting isPickingImage flag');
                  Routes.isPickingImage = true;
                  Navigator.of(context).pop();
                  // Use a delayed future to ensure the dialog is closed before opening camera
                  Future.microtask(() => _pickImageFromCamera());
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: AppColors.primaryColor),
                title: const Text('Gallery'),
                onTap: () {
                  debugPrint('Gallery selected, setting isPickingImage flag');
                  Routes.isPickingImage = true;
                  Navigator.of(context).pop();
                  // Use a delayed future to ensure the dialog is closed before opening gallery
                  Future.microtask(() => _pickImageFromGallery());
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
      debugPrint('Starting camera image pick');
      // Set flag to indicate we're picking an image
      setState(() {
        _isPickingImage = true;
        _imagePickStartTime = DateTime.now();
      });
      
      // Close the image source dialog before opening camera
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      // Check and request camera permission on mobile
      if (!kIsWeb) {
        try {
          final status = await Permission.camera.request();
          if (status != PermissionStatus.granted) {
            debugPrint('Camera permission denied');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Camera permission is required to take photos'),
                  backgroundColor: Colors.red,
                ),
              );
              
              // Open app settings if permanently denied
              if (status == PermissionStatus.permanentlyDenied) {
                await openAppSettings();
              }
            }
            setState(() {
              _isPickingImage = false;
              _imagePickStartTime = null;
            });
            Routes.isPickingImage = false;
            debugPrint('Reset isPickingImage flag to false (permission denied)');
            return;
          }
        } catch (permissionError) {
          debugPrint('Error requesting camera permission: $permissionError');
          // On some devices, we might still be able to pick an image even without explicit permission
        }
      }
      
      debugPrint('Calling image picker for camera');
      final XFile? pickedImage = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      debugPrint('Image picker returned: ${pickedImage != null ? 'image captured' : 'no image'}');
      
      // Reset picking flag
      if (mounted) {
        setState(() {
          _isPickingImage = false;
          _imagePickStartTime = null;
        });
      }
      Routes.isPickingImage = false;
      debugPrint('Reset isPickingImage flag to false (after picking)');
      
      if (pickedImage != null) {
        if (kIsWeb) {
          // For web, we need to read the image as bytes
          final bytes = await pickedImage.readAsBytes();
          
          if (!mounted) return;
          setState(() {
            _webImage = bytes;
            _pickedImage = pickedImage;
          });
        } else {
          // For mobile, we can use the file directly
          if (!mounted) return;
          setState(() {
            _pickedImage = pickedImage;
            _webImage = null; // Clear web image data for mobile
          });
        }
        debugPrint('Image successfully set in state');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No image captured'),
              backgroundColor:  AppColors.primaryColor,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking image from camera: $e');
      // Reset picking flag
      if (mounted) {
        setState(() {
          _isPickingImage = false;
          _imagePickStartTime = null;
        });
      }
      Routes.isPickingImage = false;
      debugPrint('Reset isPickingImage flag to false (error case)');
      
      // Special handling for web camera errors
      if (kIsWeb) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Camera access denied or not supported by your browser. Please check browser permissions or try selecting from gallery.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
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
  }

  /// Pick image from gallery
  Future<void> _pickImageFromGallery() async {
    try {
      debugPrint('Starting gallery image pick');
      // Set flag to indicate we're picking an image
      setState(() {
        _isPickingImage = true;
        _imagePickStartTime = DateTime.now();
      });
      
      // Close the image source dialog before opening gallery
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      // Check and request gallery permission on mobile
      if (!kIsWeb) {
        try {
          if (Platform.isAndroid) {
            // On Android 13+ this maps to READ_MEDIA_IMAGES
            var status = await Permission.photos.request();
            if (status != PermissionStatus.granted) {
              // Fallback for Android 12 and below
              status = await Permission.storage.request();
            }
            if (status != PermissionStatus.granted) {
              debugPrint('Gallery permission denied');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Gallery permission is required to select photos'),
                    backgroundColor: Colors.red,
                  ),
                );
                if (status == PermissionStatus.permanentlyDenied) {
                  await openAppSettings();
                }
              }
              setState(() {
                _isPickingImage = false;
                _imagePickStartTime = null;
              });
              Routes.isPickingImage = false;
              debugPrint('Reset isPickingImage flag to false (permission denied)');
              return;
            }
          } else if (Platform.isIOS) {
            // iOS: PHPicker does not require Photos permission; proceed without requesting
          }
        } catch (permissionError) {
          debugPrint('Error requesting gallery permission: $permissionError');
          // On some devices, we might still be able to pick an image even without explicit permission
        }
      }
      
      debugPrint('Calling image picker for gallery');
      final XFile? pickedImage = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      debugPrint('Image picker returned: ${pickedImage != null ? 'image selected' : 'no image'}');
      
      // Reset picking flag
      if (mounted) {
        setState(() {
          _isPickingImage = false;
          _imagePickStartTime = null;
        });
      }
      Routes.isPickingImage = false;
      debugPrint('Reset isPickingImage flag to false (after picking)');
      
      if (pickedImage != null) {
        if (kIsWeb) {
          // For web, we need to read the image as bytes
          final bytes = await pickedImage.readAsBytes();
          
          if (!mounted) return;
          setState(() {
            _webImage = bytes;
            _pickedImage = pickedImage;
          });
        } else {
          // For mobile, we can use the file directly
          if (!mounted) return;
          setState(() {
            _pickedImage = pickedImage;
            _webImage = null; // Clear web image data for mobile
          });
        }
        debugPrint('Image successfully set in state');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No image selected'),
              backgroundColor:  AppColors.primaryColor,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
      // Reset picking flag
      if (mounted) {
        setState(() {
          _isPickingImage = false;
          _imagePickStartTime = null;
        });
      }
      Routes.isPickingImage = false;
      debugPrint('Reset isPickingImage flag to false (error case)');
      
      // Special handling for web gallery errors
      if (kIsWeb) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gallery access denied or not supported by your browser. Please check browser permissions.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
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
  }

  Widget _buildCustomDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 4),
            if (label.contains('*'))
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: value,
          validator: validator,
          decoration: InputDecoration(
            isDense: true,
            fillColor: Colors.white,
            filled: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppColors.primaryTextColor,
                width: 0.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Colors.black26,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppColors.primaryTextColor,
                width: 1,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1.2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1.5,
              ),
            ),
          ),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black,
          ),
          icon: const Icon(
            Icons.arrow_drop_down,
            color: AppColors.secondaryTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomTextField({
    required String label,
    required TextEditingController txtController,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
    bool isRequired = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 4),
            if (isRequired)
              Image.asset(
              IconsAssets.star,
                width: 8,
                height: 8,
                color: Colors.red,
              ),
          ],
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: txtController,
          validator: validator,
          onChanged: onChanged,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black,
          ),
          cursorColor: AppColors.primaryTextColor,
          decoration: InputDecoration(
            isDense: true,
            fillColor: Colors.white,
            filled: true,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: maxLines > 1 ? 12 : 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppColors.primaryTextColor,
                width: 0.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Colors.black26,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppColors.primaryTextColor,
                width: 1,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1.2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Get current location
  Future<void> _getCurrentLocation() async {
    try {
      // Show loading indicator for location
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(kIsWeb 
              ? 'Requesting location access from browser...' 
              : 'Getting current location...'),
            duration: const Duration(seconds: 3),
          ),
        );
      }

      final location = await _locationService.getCurrentLocation();
      
      if (location != null) {
        setState(() {
          _currentLatitude = location['latitude']!.toString();
          _currentLongitude = location['longitude']!.toString();
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Location obtained: $_currentLatitude, $_currentLongitude'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(kIsWeb 
                ? 'Location access denied or unavailable. Please allow location access in your browser settings.'
                : 'Unable to get current location. Please check location permissions.'),
              backgroundColor:  AppColors.primaryColor,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Save visit method
  Future<void> _saveVisit() async {
    if (_formKey.currentState!.validate()) {
      // Check if visitor photo is picked
      if ((_pickedImage == null && _webImage == null)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Visitor photo is required to save visit. Please select a photo.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      // Check location permission before proceeding
      final locationPermissionGranted = await _checkLocationPermission();
      
      if (!locationPermissionGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission is required to save visit. Please enable location permission in settings.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      setState(() {
        _isSaving = true;
      });

      try {
        // Get current location before creating the visit
        await _getCurrentLocation();

        String id = await _secureStorage.read(key: SharedPreferenceStrings.id) ?? '';
        // Create the visit request
        final visitRequest = CreateVisitRequest(
          projectId: widget.project.id.toString(),
          visitorName: _visitorNameController.text,
          reraNumber: _reraNUmberController.text,
          teamLeaderName: _teamLeaderNameController.text,
          agentId: id,
          comments: _commentsController.text,
          visitorPhotoFile: kIsWeb ? null : (_pickedImage != null ? File(_pickedImage!.path) : null),
          visitorPhotoBytes: kIsWeb ? _webImage : null,
          lat: _currentLatitude.isNotEmpty ? _currentLatitude : '0.0',
          long: _currentLongitude.isNotEmpty ? _currentLongitude : '0.0',
          dateTime: DateTime.now().toString(),
        );

        // Call the API to create the visit
        final authApiRepository = AuthApiRepository();
        final result = await authApiRepository.createVisit(visitRequest);

        if (result['success']) {
          if (mounted) {
            setState(() {
              _isSaving = false;
              _visitorNameController.text = '';
              _teamLeaderNameController.text = '';
              _reraNUmberController.text = '';
              _commentsController.text = '';
              // Clear the picked image
              _pickedImage = null;
              _webImage = null;
            });
            // Navigator.pop(context, true); // Return true to indicate success
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Visit created successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to create visit: ${result['message']}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creating visit: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }
  
  /// Check if location permission is granted
  Future<bool> _checkLocationPermission() async {
    try {
      // For web platform, check using geolocator
      if (kIsWeb) {
        final permission = await Geolocator.checkPermission();
        return permission == LocationPermission.whileInUse || 
               permission == LocationPermission.always;
      }
      
      // For mobile platforms, use permission_handler
      final status = await Permission.locationWhenInUse.status;
      if (status.isGranted) {
        return true;
      } else if (status.isPermanentlyDenied) {
        // Open app settings if permanently denied
        await openAppSettings();
        return false;
      } else {
        // Request permission
        final requestedStatus = await Permission.locationWhenInUse.request();
        return requestedStatus.isGranted;
      }
    } catch (e) {
      debugPrint('Error checking location permission: $e');
      return false;
    }
  }

}