import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
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
import '../providers/analytics_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddVisitDialog extends ConsumerStatefulWidget {
  final Project project;
  
  const AddVisitDialog({super.key, required this.project});

  @override
  ConsumerState<AddVisitDialog> createState() => _AddVisitDialogState();
}

class _AddVisitDialogState extends ConsumerState<AddVisitDialog>
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
  String? selectedVisitType; // Store selected visit type
  bool _isSaving = false;
  String _currentLatitude = '';
  String _currentLongitude = '';
  bool _isInBackground = false;
  bool _isPickingImage = false;
  DateTime? _imagePickStartTime;
  bool _isTooFarFromProject = false; // Track if user is too far from project

  final List<String> agents = ["Sarah Johnson", "Michael Smith", "Emily Brown"];
  
  // Visit type options with keys and labels
  final List<Map<String, String>> visitTypes = [
    {'key': 'office_visit', 'label': 'Office Visit'},
    {'key': 'project_visit', 'label': 'Project Visit'},
    {'key': 'event_visit', 'label': 'Event Visit'},
  ];

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    debugPrint("Project Name: ${widget.project.name}");
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    // Get initial location when dialog opens
    _getCurrentLocation();
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
        // Use context.go to navigate back to dashboard instead of pop
        if (mounted) {
          context.go(Routes.dashboardScreen);
        }
        return false; // Prevent default pop behavior
      },
      child: Scaffold(
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
              // Use context.go to navigate back to dashboard instead of pop
              context.go(Routes.dashboardScreen);
            },
          ),
        ),
        body: GestureDetector(
          onTap: (){
            FocusScope.of(context).unfocus();
          },
          child: kIsWeb 
            ? _buildWebLayout()
            : _buildMobileLayout(),
        ),
      ),
    );
  }

  Widget _buildWebLayout() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Card(
            elevation: 4,
            shadowColor: Colors.black.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Section
                    Row(
                      children: [
                        Icon(
                          Icons.add_business_rounded,
                          color: AppColors.primaryColor,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Add Visit",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryTextColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Fill in the details to add a new visit",
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Two Column Layout for Web
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column
                        Expanded(
                          child: Column(
                            children: [
                              _buildCustomTextField(
                                label: "Visitor Name",
                                txtController: _visitorNameController,
                                isRequired: true,
                                maxLength: 30,
                                validator: (value) => value == null || value.isEmpty ? "Enter visitor name" : null,
                              ),
                              const SizedBox(height: 20),
                              _buildCustomTextField(
                                label: "RERA Number",
                                txtController: _reraNUmberController,
                                isRequired: true,
                                maxLength: 25,
                                validator: (value) => value == null || value.isEmpty ? "Enter your RERA number" : null,
                              ),
                              const SizedBox(height: 20),
                              _buildCustomTextField(
                                label: "Team Leader Name",
                                txtController: _teamLeaderNameController,
                                isRequired: true,
                                maxLength: 30,
                                validator: (value) => value == null || value.isEmpty ? "Enter team leader name" : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Right Column
                        Expanded(
                          child: Column(
                            children: [
                              _buildVisitTypeDropdown(),
                              if (_isTooFarFromProject && selectedVisitType == 'project_visit')
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        color: Colors.orange,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'You are more than 100 meters away from the project location.',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.orange[800],
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 20),
                              _buildVisitorPhotoSection(),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Comments Section (Full Width)
                    _buildCustomTextField(
                      label: "Comments",
                      txtController: _commentsController,
                      maxLines: 3,
                      maxLength: 150,
                    ),

                    const SizedBox(height: 32),

                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: 140,
                          child: CustomButton(
                            backgroundColor: Colors.white,
                            textColor: AppColors.primaryTextColor,
                            borderColor: AppColors.primaryTextColor,
                            height: 48,
                            text: "Cancel",
                            onPressed: () => context.go(Routes.dashboardScreen),
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 140,
                          child: CustomButton(
                            height: 48,
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
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
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
                const SizedBox(height: 16),

                _buildCustomTextField(
                  label: "Visitor Name",
                  txtController: _visitorNameController,
                  isRequired: true,
                  maxLength: 30,
                  validator: (value) => value == null || value.isEmpty ? "Enter visitor name" : null,
                ),

                const SizedBox(height: 12),

                _buildCustomTextField(
                  label: "RERA Number",
                  txtController: _reraNUmberController,
                  isRequired: true,
                  maxLength: 25,
                  validator: (value) => value == null || value.isEmpty ? "Enter your RERA number" : null,
                ),

                const SizedBox(height: 12),

                _buildCustomTextField(
                  label: "Team Leader Name",
                  txtController: _teamLeaderNameController,
                  isRequired: true,
                  maxLength: 30,
                  validator: (value) => value == null || value.isEmpty ? "Enter team leader name" : null,
                ),

                const SizedBox(height: 12),

                _buildVisitTypeDropdown(),
                
                // Warning message if too far from project for project visit
                if (_isTooFarFromProject && selectedVisitType == 'project_visit')
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'You are more than 100 meters away from the project location.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[800],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 12),

                _buildVisitorPhotoSection(),
                const SizedBox(height: 12),

                _buildCustomTextField(
                  label: "Comments",
                  txtController: _commentsController,
                  maxLines: 3,
                  maxLength: 150,
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        backgroundColor: Colors.white,
                        textColor: AppColors.primaryTextColor,
                        borderColor: AppColors.primaryTextColor,
                        height: 40,
                        text: "Cancel",
                        onPressed: () => context.go(Routes.dashboardScreen),
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
    );
  }

  Widget _buildVisitTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Type",
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
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: selectedVisitType,
          hint: Text(
            "Select type",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
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
          dropdownColor: Colors.white,
          items: visitTypes.map((visitType) {
            return DropdownMenuItem<String>(
              value: visitType['key'],
              child: Text(
                visitType['label']!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedVisitType = value;
            });
            debugPrint('Visit type changed to: $value');
            // If Project Visit is selected, show warning based on already-checked distance
            if (value == 'project_visit') {
              // Check distance - trigger check even if location not ready yet
              _checkDistanceFromProject();
              // Also schedule checks to ensure location is ready
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted && selectedVisitType == 'project_visit') {
                  _checkDistanceFromProject();
                }
              });
              Future.delayed(const Duration(milliseconds: 1500), () {
                if (mounted && selectedVisitType == 'project_visit') {
                  _checkDistanceFromProject();
                }
              });
            } else {
              // Clear warning for other types
              setState(() {
                _isTooFarFromProject = false;
              });
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Select visit type";
            }
            return null;
          },
          icon: const Icon(
            Icons.arrow_drop_down,
            color: AppColors.secondaryTextColor,
          ),
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildVisitorPhotoSection() {
    final photoSize = kIsWeb ? 140.0 : 100.0;
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
            height: photoSize,
            width: photoSize,
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.secondaryTextColor,
                width: kIsWeb ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(kIsWeb ? 12 : 8),
              color: Colors.grey[100],
              boxShadow: kIsWeb ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ] : null,
            ),
            child: _pickedImage != null || _webImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(kIsWeb ? 12 : 8),
                    child: kIsWeb 
                        ? (_webImage != null
                            ? Image.memory(
                                _webImage!,
                                fit: BoxFit.cover,
                                width: photoSize,
                                height: photoSize,
                              )
                            : Container())
                        : (_pickedImage != null
                            ? Image.file(
                                File(_pickedImage!.path),
                                fit: BoxFit.cover,
                                width: photoSize,
                                height: photoSize,
                              )
                            : Container()),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        color: AppColors.secondaryTextColor,
                        size: kIsWeb ? 36 : 30,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        kIsWeb ? "Click to upload" : "Tap to upload",
                        style: TextStyle(
                          fontSize: kIsWeb ? 13 : 12,
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
      
      // Image source dialog is already closed by the onTap handler
      
      // Check and request camera permission on mobile
      if (!kIsWeb) {
        try {
          final status = await Permission.camera.request();
          if (status != PermissionStatus.granted) {
            debugPrint('Camera permission denied');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Camera permission is required to take photos', style: TextStyle(color: Colors.white)),
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
              content: Text('No image captured', style: TextStyle(color: Colors.white)),
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
              content: Text('Camera access denied or not supported by your browser. Please check browser permissions or try selecting from gallery.', style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to pick image from camera: ${e.toString()}', style: const TextStyle(color: Colors.white)),
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
      
      // Image source dialog is already closed by the onTap handler
      
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
                    content: Text('Gallery permission is required to select photos', style: TextStyle(color: Colors.white)),
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
              content: Text('Gallery access denied or not supported by your browser. Please check browser permissions.', style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to pick image from gallery: ${e.toString()}', style: const TextStyle(color: Colors.white)),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildCustomTextField({
    required String label,
    required TextEditingController txtController,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
    bool isRequired = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    final isWeb = kIsWeb;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: isWeb ? 15 : 14,
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
        SizedBox(height: isWeb ? 8 : 4),
        TextFormField(
          controller: txtController,
          validator: validator,
          onChanged: onChanged,
          maxLines: maxLines,
          keyboardType: keyboardType,
          maxLength: maxLength,
          style: TextStyle(
            fontSize: isWeb ? 15 : 14,
            color: Colors.black,
          ),
          cursorColor: AppColors.primaryTextColor,
          decoration: InputDecoration(
            isDense: true,
            fillColor: Colors.white,
            filled: true,
            contentPadding: EdgeInsets.symmetric(
              horizontal: isWeb ? 16 : 12,
              vertical: isWeb ? (maxLines > 1 ? 16 : 18) : (maxLines > 1 ? 12 : 14),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isWeb ? 10 : 8),
              borderSide: BorderSide(
                color: AppColors.primaryTextColor,
                width: isWeb ? 1 : 0.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isWeb ? 10 : 8),
              borderSide: BorderSide(
                color: isWeb ? Colors.grey[300]! : Colors.black26,
                width: isWeb ? 1.5 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isWeb ? 10 : 8),
              borderSide: BorderSide(
                color: AppColors.primaryColor,
                width: isWeb ? 2 : 1,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isWeb ? 10 : 8),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1.2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isWeb ? 10 : 8),
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
      final location = await _locationService.getCurrentLocation();
      
      if (location != null) {
        setState(() {
          _currentLatitude = location['latitude']!.toString();
          _currentLongitude = location['longitude']!.toString();
        });
        
        // Check distance if project visit is selected
        if (mounted) {
          _checkDistanceFromProject();
        }
        
        if (mounted) {
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(
          //     content: Text('Location obtained: $_currentLatitude, $_currentLongitude'),
          //     backgroundColor: Colors.green,
          //     duration: const Duration(seconds: 3),
          //   ),
          // );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(kIsWeb 
                ? 'Location access denied or unavailable. Please allow location access in your browser settings.'
                : 'Unable to get current location. Please check location permissions.', style: const TextStyle(color: Colors.white)),
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
            content: Text('Error getting location: $e', style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Check distance from project if project visit is selected
  void _checkDistanceFromProject() {
    debugPrint('Checking distance - selectedVisitType: $selectedVisitType, location: $_currentLatitude, $_currentLongitude');
    
    // Only check if "Project Visit" is selected
    if (selectedVisitType != 'project_visit') {
      setState(() {
        _isTooFarFromProject = false;
      });
      return;
    }

    // Check if we have location and project coordinates
    if (_currentLatitude.isEmpty || _currentLongitude.isEmpty) {
      debugPrint('Location not ready yet');
      setState(() {
        _isTooFarFromProject = false;
      });
      return;
    }

    if (widget.project.latitude == null || widget.project.longitude == null) {
      debugPrint('Project coordinates not available');
      setState(() {
        _isTooFarFromProject = false;
      });
      return;
    }

    // Check distance
    final locationService = LocationService();
    final userLat = double.tryParse(_currentLatitude);
    final userLng = double.tryParse(_currentLongitude);
    
    debugPrint('User location: $userLat, $userLng, Project location: ${widget.project.latitude}, ${widget.project.longitude}');
    
    if (userLat != null && userLng != null) {
      final isWithinDistance = locationService.isWithinDistance(
        userLat,
        userLng,
        widget.project.latitude,
        widget.project.longitude,
        100.0, // 100 meters
      );
      
      debugPrint('isWithinDistance result: $isWithinDistance');
      setState(() {
        _isTooFarFromProject = (isWithinDistance == false);
      });
      debugPrint('Warning should show: $_isTooFarFromProject');
    }
  }

  // Save visit method
  Future<void> _saveVisit() async {
    debugPrint('_saveVisit called');
    
    if (!_formKey.currentState!.validate()) {
      debugPrint('Form validation failed');
      return;
    }
    
    debugPrint('Form validation passed');
    
    // Check if visitor photo is picked
    if ((_pickedImage == null && _webImage == null)) {
      debugPrint('Visitor photo not selected');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Visitor photo is required to save visit. Please select a photo.', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    debugPrint('Visitor photo check passed');
    
    // Check location permission before proceeding
    // On web, we'll be more lenient and allow proceeding even if permission is not granted
    // The location will be requested when getting current location
    debugPrint('Checking location permission...');
    final locationPermissionGranted = await _checkLocationPermission();
    debugPrint('Location permission result: $locationPermissionGranted');
    
    if (!locationPermissionGranted && !kIsWeb) {
      debugPrint('Location permission denied (mobile)');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission is required to save visit. Please enable location permission in settings.', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    // On web, we'll proceed even if permission check fails, as browser will prompt
    if (!locationPermissionGranted && kIsWeb) {
      debugPrint('Location permission not granted on web, but proceeding (browser will prompt)');
    }
    
    debugPrint('Setting saving state');
    setState(() {
      _isSaving = true;
    });

    try {
      debugPrint('Getting current location...');
      // Get current location before creating the visit
      // If location fails, we'll use default values (0.0, 0.0)
      try {
        await _getCurrentLocation();
        debugPrint('Location obtained: $_currentLatitude, $_currentLongitude');
      } catch (locationError) {
        debugPrint('Error getting location, will use default values: $locationError');
        // Set default values if location fails
        if (_currentLatitude.isEmpty || _currentLongitude.isEmpty) {
          _currentLatitude = '0.0';
          _currentLongitude = '0.0';
        }
      }

        debugPrint('Reading user ID from secure storage...');
        String id = await _secureStorage.read(key: SharedPreferenceStrings.id) ?? '';
        debugPrint('User ID: $id');
        
        // Compute is_at_project_location: true if within 100m, else false
        bool isAtProjectLocation = false;
        final userLat = double.tryParse(_currentLatitude);
        final userLng = double.tryParse(_currentLongitude);
        if (userLat != null && userLng != null &&
            widget.project.latitude != null && widget.project.longitude != null) {
          final within = _locationService.isWithinDistance(
            userLat,
            userLng,
            widget.project.latitude,
            widget.project.longitude,
            100.0,
          );
          isAtProjectLocation = (within == true);
        }
        debugPrint('isAtProjectLocation: $isAtProjectLocation');
        
        // Create the visit request
        debugPrint('Creating visit request...');
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
          type: selectedVisitType ?? 'office_visit', // Default to office_visit if not selected
          isAtProjectLocation: isAtProjectLocation,
        );
        debugPrint('Visit request created, calling API...');

        // Call the API to create the visit
        final authApiRepository = AuthApiRepository();
        debugPrint('About to call createVisit API...');
        final result = await authApiRepository.createVisit(visitRequest);
        debugPrint('API call completed. Result: $result');

        if (result['success']) {
          // Log analytics event for visit creation
          try {
            final analyticsService = ref.read(analyticsProvider);
            await analyticsService.logVisitCreated(
              visitType: selectedVisitType ?? 'office_visit',
              projectId: widget.project.id.toString(),
              projectName: widget.project.name,
              hasPhoto: (_pickedImage != null || _webImage != null),
              hasComments: _commentsController.text.isNotEmpty,
            );
          } catch (e) {
            debugPrint('Error logging visit creation analytics: $e');
          }

          if (mounted) {
            setState(() {
              _isSaving = false;
              _visitorNameController.text = '';
              _teamLeaderNameController.text = '';
              _reraNUmberController.text = '';
              _commentsController.text = '';
              selectedVisitType = null; // Clear selected type
              // Clear the picked image
              _pickedImage = null;
              _webImage = null;
            });
            context.go(Routes.dashboardScreen); // Navigate back to dashboard
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Visit created successfully', style: TextStyle(color: Colors.white)),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to create visit: ${result['message']}', style: const TextStyle(color: Colors.white)),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e, stackTrace) {
        debugPrint('Error creating visit: $e');
        debugPrint('Stack trace: $stackTrace');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creating visit: $e', style: const TextStyle(color: Colors.white)),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        debugPrint('Finally block - resetting saving state');
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
        debugPrint('Checking location permission for web...');
        var permission = await Geolocator.checkPermission();
        debugPrint('Initial permission status: $permission');
        
        // If denied, try to request permission
        if (permission == LocationPermission.denied) {
          debugPrint('Permission denied, requesting...');
          permission = await Geolocator.requestPermission();
          debugPrint('Permission after request: $permission');
        }
        
        final isGranted = permission == LocationPermission.whileInUse || 
                          permission == LocationPermission.always;
        debugPrint('Location permission granted: $isGranted');
        return isGranted;
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
      // On web, if permission check fails, we'll still try to proceed
      // as the location might be obtained through browser prompt
      if (kIsWeb) {
        debugPrint('Permission check failed on web, will attempt to get location anyway');
        return true; // Allow proceeding, location will be requested when getting location
      }
      return false;
    }
  }

