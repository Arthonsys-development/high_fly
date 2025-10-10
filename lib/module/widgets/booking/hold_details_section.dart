import 'package:flutter/material.dart';
import '../../../data/models/hold_details_model.dart';
import '../../global/widgets/custom_text_field.dart';
import 'header_icon_widget.dart';
import 'action_buttons.dart';

class HoldDetailsSection extends StatefulWidget {
  final String title;
  final VoidCallback? onPrevious;
  final Function(HoldDetails?)? onNext;
  final String? nextButtonText;

  const HoldDetailsSection({
    super.key,
    required this.title,
    this.onPrevious,
    this.onNext,
    this.nextButtonText,
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

  @override
  void initState() {
    super.initState();
    _holdDetails = const HoldDetails(
      associateNameOrSelf: '',
      reraNumber: '',
      teamLeaderName: '',
      clientAadhar: '',
      additionalNotes: '',
    );
    
    _associateNameController = TextEditingController();
    _reraNumberController = TextEditingController();
    _teamLeaderController = TextEditingController();
    _clientAadharController = TextEditingController();
    _additionalNotesController = TextEditingController();
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 20, bottom: 20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          
          // Header with icon
          const HeaderIconWidget(
            icon: Icons.schedule,
            title: 'Hold Details',
            subtitle: 'Enter details to hold the plot for 24 hours',
          ),
          
          const SizedBox(height: 40),
          
          // Associate Name or Self field
          CustomTextField(
            titleText: 'Associate Name or Self',
            controller: _associateNameController,
            hintText: 'Enter associate name or self',
            isMandatory: true,
            borderRadius: 6,
            onChanged: (value) {
              setState(() {
                _holdDetails = _holdDetails.copyWith(associateNameOrSelf: value);
              });
            },
          ),
          
          const SizedBox(height: 24),
          
          // RERA Number field
          CustomTextField(
            titleText: 'RERA Number',
            controller: _reraNumberController,
            hintText: 'Enter RERA number',
            isMandatory: true,
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
            isMandatory: true,
            keyboardType: TextInputType.number,
            borderRadius: 6,
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
            onNext: _canProceed() ? () => widget.onNext?.call(_holdDetails) : null,
            isPreviousEnabled: widget.onPrevious != null,
            isNextEnabled: _canProceed(),
            nextButtonText: widget.nextButtonText,
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  bool _canProceed() {
    // Only required fields need to be filled
    return _holdDetails.associateNameOrSelf.isNotEmpty &&
           _holdDetails.reraNumber.isNotEmpty &&
           _holdDetails.clientAadhar.isNotEmpty;
  }
}
