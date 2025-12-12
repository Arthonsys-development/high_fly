import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/constant/const_assets.dart';
import '../../../data/models/hold_details_model.dart';
import '../../global/widgets/custom_text_field.dart';
import 'header_icon_widget.dart';
import 'action_buttons.dart';

class HoldDetailsSection extends StatefulWidget {
  final String title;
  final VoidCallback? onPrevious;
  final Function(HoldDetails?)? onNext;
  final String? nextButtonText;
  final HoldDetails? initialHoldDetails;

  const HoldDetailsSection({
    super.key,
    required this.title,
    this.onPrevious,
    this.onNext,
    this.nextButtonText,
    this.initialHoldDetails,
  });

  @override
  State<HoldDetailsSection> createState() => _HoldDetailsSectionState();
}

class _HoldDetailsSectionState extends State<HoldDetailsSection> {
  late HoldDetails _holdDetails;
  late TextEditingController _associateNameController;
  late TextEditingController _reraNumberController;
  late TextEditingController _teamLeaderController;
  late TextEditingController _clientAadharController;
  late TextEditingController _additionalNotesController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

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
  }

  @override
  void dispose() {
    _associateNameController.dispose();
    _reraNumberController.dispose();
    _teamLeaderController.dispose();
    _clientAadharController.dispose();
    _additionalNotesController.dispose();
    super.dispose();
  }

  String? _validateClientAadhar(String? value) {
    // Since the field is optional, only validate if user has entered something
    if (value == null || value.isEmpty) {
      return null; // Empty is valid since field is optional
    }
    // If entered, must be exactly 12 digits
    if (value.length != 12) {
      return 'Aadhar number must be exactly 12 digits';
    }
    return null; // Valid
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 20, bottom: 20),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
          const SizedBox(height: 20),
          
          // Header with icon
          HeaderIconWidget(
            icon: IconsAssets.holdTimeIcon,
            title: 'Hold Details',
            subtitle: 'Enter details to hold the plot for 24 hours',
          ),
          
          const SizedBox(height: 40),
          
          // Associate Name or Self field
          // CustomTextField(
          //   titleText: 'Associate Name or Self',
          //   controller: _associateNameController,
          //   hintText: 'Enter associate name or self',
          //   isMandatory: false,
          //   maxLength: 30,
          //   borderRadius: 6,
          //   onChanged: (value) {
          //     setState(() {
          //       _holdDetails = _holdDetails.copyWith(associateNameOrSelf: value);
          //     });
          //   },
          // ),
          
          // const SizedBox(height: 24),
          
          // RERA Number field
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
          
          const SizedBox(height: 24),
          
          // Team Leader Name field
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
          
          const SizedBox(height: 24),
          
          // Client's Aadhar field
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
          
          const SizedBox(height: 24),
          
          // Additional Notes field
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
          
          const SizedBox(height: 40),
          
          // Action buttons
          ActionButtons(
            onPrevious: widget.onPrevious,
            onNext: () {
              // Validate form before proceeding
              if (_formKey.currentState?.validate() ?? true) {
                widget.onNext?.call(_holdDetails);
              }
            },
            isPreviousEnabled: widget.onPrevious != null,
            isNextEnabled: true,
            nextButtonText: widget.nextButtonText,
          ),
          
          const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

}
