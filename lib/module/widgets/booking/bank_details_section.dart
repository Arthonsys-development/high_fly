import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:highfly/config/constant/const_assets.dart';
import 'package:highfly/config/utils.dart';
import '../../../data/models/bank_details_model.dart';
import '../../../config/constant/app_colors.dart';
import '../../global/widgets/custom_text_field.dart';
import 'header_icon_widget.dart';
import 'action_buttons.dart';
import 'bank_selection_dialog.dart';

class BankDetailsSection extends StatefulWidget {
  final String title;
  final String nextButtonText;
  final VoidCallback? onPrevious;
  final Function(BankDetails?)? onNext;
  final BankDetails? initialBankDetails;

  const BankDetailsSection({
    super.key,
    required this.title,
    required this.nextButtonText,
    this.onPrevious,
    this.onNext,
    this.initialBankDetails,
  });

  @override
  State<BankDetailsSection> createState() => _BankDetailsSectionState();
}

class _BankDetailsSectionState extends State<BankDetailsSection> {
  late BankDetails _bankDetails;
  late TextEditingController _accountHolderNameController;
  late TextEditingController _branchNameController;
  late TextEditingController _accountNumberController;
  late TextEditingController _ifscCodeController;
  late TextEditingController _contactNumberController;
  late TextEditingController _accountTypeController;

  @override
  void initState() {
    super.initState();
    // Initialize with provided bank details if available, otherwise use defaults
    _bankDetails = widget.initialBankDetails ?? const BankDetails();
    
    _accountHolderNameController = TextEditingController(
      text: _bankDetails.accountHolderName ?? ''
    );
    _branchNameController = TextEditingController(
      text: _bankDetails.branchName ?? ''
    );
    _accountNumberController = TextEditingController(
      text: _bankDetails.accountNumber ?? ''
    );
    _ifscCodeController = TextEditingController(
      text: _bankDetails.ifscCode ?? ''
    );
    _contactNumberController = TextEditingController(
      text: _bankDetails.contactNumber ?? ''
    );
    _accountTypeController = TextEditingController(
      text: _bankDetails.accountType != null
          ? (BankConstants.accountTypes[_bankDetails.accountType] ?? '')
          : ''
    );
  }

  @override
  void dispose() {
    _accountHolderNameController.dispose();
    _branchNameController.dispose();
    _accountNumberController.dispose();
    _ifscCodeController.dispose();
    _contactNumberController.dispose();
    _accountTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 20, bottom: 20),
      child: Column(
        children: [
          // Header
          HeaderIconWidget(
            icon:IconsAssets.bankIcon,
            title: widget.title,
            subtitle: 'Enter bank information',
          ),
          
          const SizedBox(height: 40),
          
          // Account Holder Name field
          CustomTextField(
            titleText: 'Account Holder Name',
            controller: _accountHolderNameController,
            hintText: 'Enter account holder name',
            isMandatory: true,
            borderRadius: 6,
            maxLength: 30,
            onChanged: (value) {
              setState(() {
                _bankDetails = _bankDetails.copyWith(accountHolderName: value);
              });
            },
          ),
          
          const SizedBox(height: 24),
          
          // Branch Name field
          CustomTextField(
            titleText: 'Branch Name',
            controller: _branchNameController,
            hintText: 'Enter branch name',
            isMandatory: true,
            borderRadius: 6,
            maxLength: 30,
            onChanged: (value) {
              setState(() {
                _bankDetails = _bankDetails.copyWith(branchName: value);
              });
            },
          ),
          
          const SizedBox(height: 24),
          
          // Account Number field
          CustomTextField(
            titleText: 'Account Number',
            controller: _accountNumberController,
            hintText: 'Enter account number',
            isMandatory: true,
            maxLength: 18,
            keyboardType: TextInputType.number,
            borderRadius: 6,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            onChanged: (value) {
              setState(() {
                _bankDetails = _bankDetails.copyWith(accountNumber: value);
              });
            },
          ),
          
          const SizedBox(height: 24),
          
          // IFSC Code field
         CustomTextField(
            titleText: 'IFSC Code',
            controller: _ifscCodeController,
            hintText: 'Enter IFSC Code',
            isMandatory: true,
            maxLength: 11,
            borderRadius: 6,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
              UpperCaseTextFormatter(),
              LengthLimitingTextInputFormatter(11),
            ],
            onChanged: (value) {
              setState(() {
                _bankDetails = _bankDetails.copyWith(ifscCode: value.toUpperCase());
              });
            },
          ),
          
          const SizedBox(height: 24),
          
          // Account Type field
          GestureDetector(
            onTap: _showAccountTypeDialog,
            child: CustomTextField(
              titleText: 'Account Type',
              controller: _accountTypeController,
              hintText: 'Select account type',
              isMandatory: true,
              borderRadius: 6,
              enabled: false,
              suffixIcon: const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.lightGreyColor,
                size: 20,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Contact Number field
          CustomTextField(
            titleText: 'Contact Number (linked with bank)',
            controller: _contactNumberController,
            hintText: 'Enter contact number',
            isMandatory: true,
            keyboardType: TextInputType.phone,
            borderRadius: 6,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            onChanged: (value) {
              setState(() {
                _bankDetails = _bankDetails.copyWith(contactNumber: value);
              });
            },
          ),
          
          const SizedBox(height: 40),
          
          // Action buttons
          ActionButtons(
            onPrevious: widget.onPrevious,
            onNext: _canProceed() ? () => widget.onNext?.call(_bankDetails) : null,
            nextButtonText: widget.nextButtonText,
            isPreviousEnabled: widget.onPrevious != null,
          ),
        ],
      ),
    );
  }

  bool _canProceed() {
    return _bankDetails.accountHolderName?.isNotEmpty == true &&
           _bankDetails.branchName?.isNotEmpty == true &&
           _bankDetails.accountNumber?.isNotEmpty == true &&
           _bankDetails.ifscCode?.isNotEmpty == true &&
           _bankDetails.accountType?.isNotEmpty == true &&
           _bankDetails.contactNumber?.isNotEmpty == true;
  }

  void _showAccountTypeDialog() {
    showDialog(
      context: context,
      builder: (context) => BankSelectionDialog(
        title: 'Select Account Type',
        options: BankConstants.accountTypes,
        selectedOption: _bankDetails.accountType,
        onOptionSelected: (value) {
          setState(() {
            _bankDetails = _bankDetails.copyWith(accountType: value);
            // Display the value (not the key) in the text field
            _accountTypeController.text = BankConstants.accountTypes[value] ?? '';
          });
        },
      ),
    );
  }
}
