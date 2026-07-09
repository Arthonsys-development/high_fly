import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/constant/const_assets.dart';
import '../../../data/models/hold_details_model.dart';
import '../../../data/models/response_model/profile_model.dart';
import '../../providers/profile_provider.dart';
import '../../global/widgets/custom_text_field.dart';
import 'header_icon_widget.dart';
import 'action_buttons.dart';

class HoldDetailsSection extends ConsumerStatefulWidget {
  final String title;
  final VoidCallback? onPrevious;
  final Function(HoldDetails?)? onNext;
  final String? nextButtonText;
  final HoldDetails? initialHoldDetails;
  final double? saleableSize;

  const HoldDetailsSection({
    super.key,
    required this.title,
    this.onPrevious,
    this.onNext,
    this.nextButtonText,
    this.initialHoldDetails,
    this.saleableSize,
  });

  @override
  ConsumerState<HoldDetailsSection> createState() => _HoldDetailsSectionState();
}

class _HoldDetailsSectionState extends ConsumerState<HoldDetailsSection> {
  late HoldDetails _holdDetails;
  late TextEditingController _associateNameController;
  late TextEditingController _reraNumberController;
  late TextEditingController _teamLeaderController;
  late TextEditingController _clientAadharController;
  late TextEditingController _additionalNotesController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  ProviderSubscription<ProfileState>? _profileSubscription;
  bool _didRequestProfileLoad = false;

  void _prefillFromCurrentUser(ProfileResponseData? profile) {
    if (profile == null) return;

    final rera = profile.reraNumber?.trim() ?? '';
    final teamLeader = profile.teamLeaderName?.trim() ?? '';

    var changed = false;

    if (_reraNumberController.text.trim().isEmpty && rera.isNotEmpty) {
      _reraNumberController.text = rera;
      _holdDetails = _holdDetails.copyWith(reraNumber: rera);
      changed = true;
    }

    if (_teamLeaderController.text.trim().isEmpty && teamLeader.isNotEmpty) {
      _teamLeaderController.text = teamLeader;
      _holdDetails = _holdDetails.copyWith(teamLeaderName: teamLeader);
      changed = true;
    }

    if (changed && mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    // Initialize with provided hold details if available, otherwise use defaults
    _holdDetails = widget.initialHoldDetails ?? const HoldDetails(
      associateNameOrSelf: '',
      reraNumber: '',
      teamLeaderName: '',
      clientAadhar: '',
      additionalNotes: '',
    );
    
    _associateNameController = TextEditingController(
      text: _holdDetails.associateNameOrSelf
    );
    _reraNumberController = TextEditingController(
      text: _holdDetails.reraNumber
    );
    _teamLeaderController = TextEditingController(
      text: _holdDetails.teamLeaderName
    );
    _clientAadharController = TextEditingController(
      text: _holdDetails.clientAadhar
    );
    _additionalNotesController = TextEditingController(
      text: _holdDetails.additionalNotes
    );

    // Prefill from current user's profile (without overriding existing values)
    _profileSubscription = ref.listenManual<ProfileState>(profileProvider, (previous, next) {
      _prefillFromCurrentUser(next.profile);
    });

    // In case profile is already loaded before this widget mounts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(profileProvider);
      _prefillFromCurrentUser(state.profile);

      // If profile isn't loaded in this flow, fetch it once.
      if (state.profile == null && !state.isLoading && !_didRequestProfileLoad) {
        _didRequestProfileLoad = true;
        ref.read(profileProvider.notifier).loadProfile();
      }
    });
  }

  @override
  void dispose() {
    _profileSubscription?.close();
    _associateNameController.dispose();
    _reraNumberController.dispose();
    _teamLeaderController.dispose();
    _clientAadharController.dispose();
    _additionalNotesController.dispose();
    super.dispose();
  }

  String? _validateClientAadhar(String? value) {
    final aadhar = value?.trim() ?? '';
    if (aadhar.isNotEmpty && aadhar.length < 12) {
      return 'Aadhaar number must be a 12-digit number.';
    }
    return null;
  }

  String? get _clientAadharInlineMessage {
    final aadhar = _clientAadharController.text.trim();
    if (aadhar.isNotEmpty && aadhar.length < 12) {
      return 'Aadhaar number must be a 12-digit number.';
    }
    return null;
  }

  bool get _showNextButton {
    final aadhar = _clientAadharController.text.trim();
    return aadhar.isEmpty || aadhar.length == 12;
  }

  @override
  Widget build(BuildContext context) {
    final spacing = kIsWeb ? 24.0 : 24.0;
    final largeSpacing = kIsWeb ? 40.0 : 40.0;
    
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: kIsWeb ? 20 : 20,
        bottom: kIsWeb ? 20 : 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Header with icon
            HeaderIconWidget(
              icon: IconsAssets.holdTimeIcon,
              title: 'Hold Details',
              subtitle: 'Enter details to hold the plot for 24 hours',
            ),
            
            SizedBox(height: largeSpacing),

            // Saleable size info banner (read-only context)
            // if (widget.saleableSize != null && widget.saleableSize! > 0) ...[
            //   Container(
            //     width: double.infinity,
            //     constraints: kIsWeb ? const BoxConstraints(maxWidth: 800) : null,
            //     padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            //     decoration: BoxDecoration(
            //       color: const Color(0xFFF0F9FF),
            //       borderRadius: BorderRadius.circular(8),
            //       border: Border.all(color: const Color(0xFFBAE6FD)),
            //     ),
            //     // child: Row(
            //     //   children: [
            //     //     const Icon(Icons.straighten_outlined, size: 16, color: Color(0xFF0284C7)),
            //     //     const SizedBox(width: 8),
            //     //     Text(
            //     //       'Saleable Size: ${widget.saleableSize!.toStringAsFixed(widget.saleableSize! % 1 == 0 ? 0 : 2)} sq yd',
            //     //       style: const TextStyle(
            //     //         fontSize: 13,
            //     //         fontWeight: FontWeight.w500,
            //     //         color: Color(0xFF0369A1),
            //     //       ),
            //     //     ),
            //     //   ],
            //     // ),
            //   ),
            //   SizedBox(height: largeSpacing),
            // ],

            // Web: Clean form layout with max width, Mobile: Stacked layout
            if (kIsWeb)
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Two-column layout for first row fields
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: CustomTextField(
                              titleText: 'RERA Number',
                              controller: _reraNumberController,
                              hintText: 'Enter RERA number',
                              isMandatory: false,
                              maxLength: 25,
                              borderRadius: 8,
                              onChanged: (value) {
                                setState(() {
                                  _holdDetails = _holdDetails.copyWith(reraNumber: value);
                                });
                              },
                            ),
                          ),
                          SizedBox(width: 20),
                          Expanded(
                            child: CustomTextField(
                              titleText: 'Team Leader Name',
                              controller: _teamLeaderController,
                              hintText: 'Enter team leader name',
                              isMandatory: false,
                              maxLength: 30,
                              borderRadius: 8,
                              onChanged: (value) {
                                setState(() {
                                  _holdDetails = _holdDetails.copyWith(teamLeaderName: value);
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: spacing),
                      
                      // Client's Aadhar field (full width)
                      CustomTextField(
                        titleText: 'Client\'s Aadhar',
                        controller: _clientAadharController,
                        hintText: 'Enter client\'s Aadhar number',
                        isMandatory: false,
                        maxLength: 12,
                        keyboardType: TextInputType.number,
                        borderRadius: 8,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(12),
                        ],
                        validator: _validateClientAadhar,
                        onChanged: (value) {
                          setState(() {
                            _holdDetails = _holdDetails.copyWith(clientAadhar: value);
                          });
                        },
                      ),
                      if (_clientAadharInlineMessage != null) ...[
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _clientAadharInlineMessage!,
                              style: const TextStyle(
                                color: Color(0xFFEF4444),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                      
                      SizedBox(height: spacing),
                      
                      // Additional Notes field (full width)
                      CustomTextField(
                        titleText: 'Additional Notes',
                        controller: _additionalNotesController,
                        hintText: 'Enter any additional notes or special instructions',
                        isMandatory: false,
                        maxLength: 150,
                        maxLines: 3,
                        borderRadius: 8,
                        onChanged: (value) {
                          setState(() {
                            _holdDetails = _holdDetails.copyWith(additionalNotes: value);
                          });
                        },
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: [
                  CustomTextField(
                    titleText: 'RERA Number',
                    controller: _reraNumberController,
                    hintText: 'Enter RERA number',
                    isMandatory: false,
                    maxLength: 25,
                    borderRadius: 6,
                    onChanged: (value) {
                      setState(() {
                        _holdDetails = _holdDetails.copyWith(reraNumber: value);
                      });
                    },
                  ),
                  SizedBox(height: spacing),
                  CustomTextField(
                    titleText: 'Team Leader Name',
                    controller: _teamLeaderController,
                    hintText: 'Enter team leader name',
                    isMandatory: false,
                    maxLength: 30,
                    borderRadius: 6,
                    onChanged: (value) {
                      setState(() {
                        _holdDetails = _holdDetails.copyWith(teamLeaderName: value);
                      });
                    },
                  ),
                  SizedBox(height: spacing),
                  CustomTextField(
                    titleText: 'Client\'s Aadhar',
                    controller: _clientAadharController,
                    hintText: 'Enter client\'s Aadhar number',
                    isMandatory: false,
                    maxLength: 12,
                    keyboardType: TextInputType.number,
                    borderRadius: 6,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(12),
                    ],
                    validator: _validateClientAadhar,
                    onChanged: (value) {
                      setState(() {
                        _holdDetails = _holdDetails.copyWith(clientAadhar: value);
                      });
                    },
                  ),
                  if (_clientAadharInlineMessage != null) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _clientAadharInlineMessage!,
                          style: const TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: spacing),
                  CustomTextField(
                    titleText: 'Additional Notes',
                    controller: _additionalNotesController,
                    hintText: 'Enter any additional notes or special instructions',
                    isMandatory: false,
                    maxLength: 150,
                    maxLines: 3,
                    borderRadius: 6,
                    onChanged: (value) {
                      setState(() {
                        _holdDetails = _holdDetails.copyWith(additionalNotes: value);
                      });
                    },
                  ),
                ],
              ),
            
            SizedBox(height: largeSpacing),
            
            // Action buttons
            ActionButtons(
              onPrevious: widget.onPrevious,
              onNext: _showNextButton ? () {
                // Validate form before proceeding
                if (_formKey.currentState?.validate() ?? true) {
                  widget.onNext?.call(_holdDetails);
                }
              } : null,
              isPreviousEnabled: widget.onPrevious != null,
              isNextEnabled: _showNextButton,
              isNextVisible: _showNextButton,
              nextButtonText: widget.nextButtonText,
            ),
            
            SizedBox(height: kIsWeb ? 20 : 20),
          ],
        ),
      ),
    );
  }

}
