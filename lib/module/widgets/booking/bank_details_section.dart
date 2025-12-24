import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

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

  String? _validateContactNumber(String? value) {
    // Since the field is optional, only validate if user has entered something
    if (value == null || value.isEmpty) {
      return null; // Empty is valid since field is optional
    }
    // If entered, must be exactly 10 digits
    if (value.length != 10) {
      return 'Contact number must be exactly 10 digits';
    }
    return null; // Valid
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
            // Header
            HeaderIconWidget(
              icon: IconsAssets.bankIcon,
              title: widget.title,
              subtitle: 'Enter bank information',
            ),
            
            SizedBox(height: largeSpacing),
            
            // Web: Clean form layout with max width, Mobile: Stacked layout
            if (kIsWeb)
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Account Holder Name field (full width)
                      CustomTextField(
                        titleText: 'Account Holder Name',
                        controller: _accountHolderNameController,
                        hintText: 'Enter account holder name',
                        isMandatory: false,
                        borderRadius: 8,
                        maxLength: 30,
                        onChanged: (value) {
                          setState(() {
                            _bankDetails = _bankDetails.copyWith(accountHolderName: value);
                          });
                        },
                      ),
                      
                      SizedBox(height: spacing),
                      
                      // Branch Name field (full width)
                      CustomTextField(
                        titleText: 'Branch Name',
                        controller: _branchNameController,
                        hintText: 'Enter branch name',
                        isMandatory: false,
                        borderRadius: 8,
                        maxLength: 30,
                        onChanged: (value) {
                          setState(() {
                            _bankDetails = _bankDetails.copyWith(branchName: value);
                          });
                        },
                      ),
                      
                      SizedBox(height: spacing),
                      
                      // Two-column layout for Account Number and IFSC Code
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: CustomTextField(
                              titleText: 'Account Number',
                              controller: _accountNumberController,
                              hintText: 'Enter account number',
                              isMandatory: false,
                              maxLength: 18,
                              keyboardType: TextInputType.number,
                              borderRadius: 8,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _bankDetails = _bankDetails.copyWith(accountNumber: value);
                                });
                              },
                            ),
                          ),
                          SizedBox(width: 20),
                          Expanded(
                            child: CustomTextField(
                              titleText: 'IFSC Code',
                              controller: _ifscCodeController,
                              hintText: 'Enter IFSC Code',
                              isMandatory: false,
                              maxLength: 11,
                              borderRadius: 8,
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
                          ),
                        ],
                      ),
                      
                      SizedBox(height: spacing),
                      
                      // Account Type field (full width)
                      GestureDetector(
                        onTap: _showAccountTypeDialog,
                        child: CustomTextField(
                          titleText: 'Account Type',
                          controller: _accountTypeController,
                          hintText: 'Select account type',
                          isMandatory: false,
                          borderRadius: 8,
                          enabled: false,
                          suffixIcon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: AppColors.lightGreyColor,
                            size: 20,
                          ),
                        ),
                      ),
                      
                      SizedBox(height: spacing),
                      
                      // Contact Number field (full width)
                      CustomTextField(
                        titleText: 'Contact Number (linked with bank)',
                        controller: _contactNumberController,
                        hintText: 'Enter contact number',
                        isMandatory: false,
                        keyboardType: TextInputType.phone,
                        borderRadius: 8,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        validator: _validateContactNumber,
                        onChanged: (value) {
                          setState(() {
                            _bankDetails = _bankDetails.copyWith(contactNumber: value);
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
                  // Account Holder Name field
                  CustomTextField(
                    titleText: 'Account Holder Name',
                    controller: _accountHolderNameController,
                    hintText: 'Enter account holder name',
                    isMandatory: false,
                    borderRadius: 6,
                    maxLength: 30,
                    onChanged: (value) {
                      setState(() {
                        _bankDetails = _bankDetails.copyWith(accountHolderName: value);
                      });
                    },
                  ),
                  
                  SizedBox(height: spacing),
                  
                  // Branch Name field
                  CustomTextField(
                    titleText: 'Branch Name',
                    controller: _branchNameController,
                    hintText: 'Enter branch name',
                    isMandatory: false,
                    borderRadius: 6,
                    maxLength: 30,
                    onChanged: (value) {
                      setState(() {
                        _bankDetails = _bankDetails.copyWith(branchName: value);
                      });
                    },
                  ),
                  
                  SizedBox(height: spacing),
                  
                  // Account Number field
                  CustomTextField(
                    titleText: 'Account Number',
                    controller: _accountNumberController,
                    hintText: 'Enter account number',
                    isMandatory: false,
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
                  
                  SizedBox(height: spacing),
                  
                  // IFSC Code field
                  CustomTextField(
                    titleText: 'IFSC Code',
                    controller: _ifscCodeController,
                    hintText: 'Enter IFSC Code',
                    isMandatory: false,
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
                  
                  SizedBox(height: spacing),
                  
                  // Account Type field
                  GestureDetector(
                    onTap: _showAccountTypeDialog,
                    child: CustomTextField(
                      titleText: 'Account Type',
                      controller: _accountTypeController,
                      hintText: 'Select account type',
                      isMandatory: false,
                      borderRadius: 6,
                      enabled: false,
                      suffixIcon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.lightGreyColor,
                        size: 20,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: spacing),
                  
                  // Contact Number field
                  CustomTextField(
                    titleText: 'Contact Number (linked with bank)',
                    controller: _contactNumberController,
                    hintText: 'Enter contact number',
                    isMandatory: false,
                    keyboardType: TextInputType.phone,
                    borderRadius: 6,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    validator: _validateContactNumber,
                    onChanged: (value) {
                      setState(() {
                        _bankDetails = _bankDetails.copyWith(contactNumber: value);
                      });
                    },
                  ),
                ],
              ),
            
            SizedBox(height: largeSpacing),
            
            // Action buttons
            ActionButtons(
              onPrevious: widget.onPrevious,
              onNext: () {
                // Validate form before proceeding
                if (_formKey.currentState?.validate() ?? true) {
                  widget.onNext?.call(_bankDetails);
                }
              },
              nextButtonText: widget.nextButtonText,
              isPreviousEnabled: widget.onPrevious != null,
            ),
            
            SizedBox(height: kIsWeb ? 20 : 20),
          ],
        ),
      ),
    );
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
