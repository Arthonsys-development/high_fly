import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../../../config/constant/const_assets.dart';
import '../../../data/models/payment_model.dart';
import '../../../config/constant/app_colors.dart';
import '../../global/widgets/custom_text_field.dart';
import 'header_icon_widget.dart';
import 'pdf_upload_widget.dart';
import 'payment_method_selection_dialog.dart';
import 'action_buttons.dart';

class PaymentDetailsSection extends StatefulWidget {
  final String title;
  final String paymentAmount;
  final VoidCallback? onPrevious;
  final Function(PaymentDetails?)? onNext;
  final String? nextButtonText;
  final PaymentDetails? initialPaymentDetails;

  const PaymentDetailsSection({
    super.key,
    required this.title,
    required this.paymentAmount,
    this.onPrevious,
    this.onNext,
    this.nextButtonText,
    this.initialPaymentDetails,
  });

  @override
  State<PaymentDetailsSection> createState() => _PaymentDetailsSectionState();
}

class _PaymentDetailsSectionState extends State<PaymentDetailsSection> {
  late PaymentDetails _paymentDetails;
  late TextEditingController _paymentAmountController;
  late TextEditingController _panNumberController;
  late TextEditingController _aadharNumberController;
  late TextEditingController _additionalNotesController;
  late TextEditingController _paymentMethodController;
  late TextEditingController _paymentTypeController;
  late TextEditingController _chequeNumberController;
  late TextEditingController _chequeDateController;
  final ImagePicker _imagePicker = ImagePicker();
  String _selectedPaymentTypeKey = '';

  @override
  void initState() {
    super.initState();
    // Initialize with provided payment details if available, otherwise use defaults
    if (widget.initialPaymentDetails != null) {
      _paymentDetails = widget.initialPaymentDetails!;
      _selectedPaymentTypeKey = widget.initialPaymentDetails!.paymentTypeKey;
    } else {
      _paymentDetails = PaymentDetails(
        paymentAmount: widget.paymentAmount,
        paymentMethod: '',
        paymentMethodKey: '',
        paymentType: '',
        paymentTypeKey: '',
        panNumber: '',
        aadharNumber: '',
        additionalNotes: '',
        chequeImageName: null,
        chequeImageBytes: null,
      );
    }
    
    _paymentAmountController = TextEditingController(
      text: widget.initialPaymentDetails?.paymentAmount ?? widget.paymentAmount
    );
    _panNumberController = TextEditingController(
      text: widget.initialPaymentDetails?.panNumber ?? ''
    );
    _aadharNumberController = TextEditingController(
      text: widget.initialPaymentDetails?.aadharNumber ?? ''
    );
    _additionalNotesController = TextEditingController(
      text: widget.initialPaymentDetails?.additionalNotes ?? ''
    );
    _paymentMethodController = TextEditingController(
      text: widget.initialPaymentDetails?.paymentMethod ?? ''
    );
    _paymentTypeController = TextEditingController(
      text: widget.initialPaymentDetails?.paymentType ?? ''
    );
    _chequeNumberController = TextEditingController(
      text: widget.initialPaymentDetails?.chequeNumber ?? ''
    );
    _chequeDateController = TextEditingController(
      text: widget.initialPaymentDetails?.chequeDate != null
          ? '${widget.initialPaymentDetails!.chequeDate!.day.toString().padLeft(2, '0')}/${widget.initialPaymentDetails!.chequeDate!.month.toString().padLeft(2, '0')}/${widget.initialPaymentDetails!.chequeDate!.year}'
          : ''
    );
  }

  @override
  void dispose() {
    _paymentAmountController.dispose();
    _panNumberController.dispose();
    _aadharNumberController.dispose();
    _additionalNotesController.dispose();
    _paymentMethodController.dispose();
    _paymentTypeController.dispose();
    _chequeNumberController.dispose();
    _chequeDateController.dispose();
    super.dispose();
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header with icon
          HeaderIconWidget(
            icon: IconsAssets.cardIcon,
            title: 'Payment Details',
            subtitle: 'Enter payment information',
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
                    // Payment Amount field (full width)
                    CustomTextField(
                      titleText: 'Payment Amount',
                      controller: _paymentAmountController,
                      isMandatory: false,
                      keyboardType: TextInputType.number,
                      hintText: 'Enter Payment Amount',
                      borderRadius: 8,
                      onChanged: (value) {
                        setState(() {
                          _paymentDetails = _paymentDetails.copyWith(paymentAmount: value);
                        });
                      },
                    ),
                    
                    SizedBox(height: spacing),
                    
                    // Payment Method field (full width)
                    GestureDetector(
                      onTap: _showPaymentMethodDialog,
                      child: CustomTextField(
                        titleText: 'Payment Method',
                        controller: _paymentMethodController,
                        hintText: 'Select Payment Method',
                        isMandatory: true,
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
                    
                    // Cheque Number and Date fields (two columns on web, only visible if Payment Method is cheque)
                    if (_paymentDetails.paymentMethodKey == PaymentMethod.cheque) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: CustomTextField(
                              titleText: 'Cheque Number',
                              controller: _chequeNumberController,
                              hintText: 'Enter cheque number',
                              isMandatory: true,
                              borderRadius: 8,
                              maxLength: 6,
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                setState(() {
                                  _paymentDetails = _paymentDetails.copyWith(chequeNumber: value);
                                });
                              },
                            ),
                          ),
                          SizedBox(width: 20),
                          Expanded(
                            child: GestureDetector(
                              onTap: _showDatePicker,
                              child: CustomTextField(
                                titleText: 'Cheque Date',
                                controller: _chequeDateController,
                                hintText: 'Select cheque date',
                                isMandatory: true,
                                borderRadius: 8,
                                enabled: false,
                                suffixIcon: const Icon(
                                  Icons.calendar_today,
                                  color: AppColors.lightGreyColor,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      _buildChequeImageUploadSection(),
                      SizedBox(height: spacing),
                    ],
                    
                    // Payment Type field (full width)
                    GestureDetector(
                      onTap: _showPaymentTypeDialog,
                      child: CustomTextField(
                        titleText: 'Payment Type',
                        controller: _paymentTypeController,
                        hintText: 'Select Payment Type',
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
                    
                    // Two-column layout for PAN Number and Aadhar Number
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: CustomTextField(
                            titleText: 'PAN Number',
                            controller: _panNumberController,
                            hintText: 'Enter PAN number',
                            isMandatory: false,
                            borderRadius: 8,
                            maxLength: 10,
                            onChanged: (value) {
                              setState(() {
                                _paymentDetails = _paymentDetails.copyWith(panNumber: value);
                              });
                            },
                          ),
                        ),
                        SizedBox(width: 20),
                        Expanded(
                          child: CustomTextField(
                            titleText: 'Aadhar Number',
                            controller: _aadharNumberController,
                            hintText: 'Enter Aadhar number',
                            isMandatory: true,
                            borderRadius: 8,
                            maxLength: 12,
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setState(() {
                                _paymentDetails = _paymentDetails.copyWith(aadharNumber: value);
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: spacing),
                    
                    // Salaried Individual checkbox (only visible if Payment Type is Finance)
                    if (_selectedPaymentTypeKey == PaymentType.finance ) ...[
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Checkbox(
                            value: _paymentDetails.isSalariedIndividual,
                            onChanged: (value) {
                              setState(() {
                                _paymentDetails = _paymentDetails.copyWith(
                                  isSalariedIndividual: value ?? false,
                                );
                              });
                            },
                            activeColor: AppColors.textFieldBGColor,
                            checkColor: AppColors.primaryColor,
                            fillColor: WidgetStateProperty.resolveWith<Color>(
                                  (Set<WidgetState> states) {
                              if (states.contains(WidgetState.selected)) {
                                return AppColors.textFieldBGColor;
                              }
                              return Colors.white;
                            },
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            side: WidgetStateBorderSide.resolveWith(
                                  (Set<WidgetState> states) {
                              if (states.contains(WidgetState.selected)) {
                                return const BorderSide(color: AppColors.dropDownBorderColor, width: 1.5);
                              }
                              return const BorderSide(color: AppColors.dropDownBorderColor, width: 1);
                            },
                            ),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Salaried Individual',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.headingTextColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                    /*
                    // Salary Slip field (only visible if Salaried Individual is checked)
                    if (_paymentDetails.isSalariedIndividual) ...[
                      PdfUploadWidget(
                        label: 'Salary Slip',
                        fileName: _paymentDetails.salarySlipPath,
                        isRequired: false,
                        uploadUrl: '/api/documents/upload/',
                        placeholderText: 'Upload salary slip (PDF only)',
                        onFileSelected: (filePath) {
                          setState(() {
                            _paymentDetails = _paymentDetails.copyWith(salarySlipPath: filePath);
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      // Form 16A field
                      PdfUploadWidget(
                        label: 'Form 16A',
                        fileName: _paymentDetails.form16APath?.split('/').last,
                        isRequired: false,
                        uploadUrl: '/api/documents/upload/',
                        placeholderText: 'Upload form 16A for reference',
                        onFileSelected: (filePath) {
                          setState(() {
                            _paymentDetails = _paymentDetails.copyWith(form16APath: filePath);
                          });
                        },
                      ),
                      SizedBox(height: spacing),
                    ],
                    */
                    // Additional Notes field (full width)
                    CustomTextField(
                      titleText: 'Additional Notes',
                      controller: _additionalNotesController,
                      hintText: 'Enter any additional notes or special instructions',
                      isMandatory: false,
                      maxLines: 3,
                      borderRadius: 8,
                      maxLength: 150,
                      onChanged: (value) {
                        setState(() {
                          _paymentDetails = _paymentDetails.copyWith(additionalNotes: value);
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
                // Payment Amount field
                CustomTextField(
                  titleText: 'Payment Amount',
                  controller: _paymentAmountController,
                  isMandatory: false,
                  keyboardType: TextInputType.number,
                  hintText: 'Enter Payment Amount',
                  borderRadius: 6,
                  onChanged: (value) {
                    setState(() {
                      _paymentDetails = _paymentDetails.copyWith(
                        paymentAmount: (value.trim().isEmpty) ? '0' : value,
                      );
                    });
                  },
                ),
                
                SizedBox(height: spacing),
                
                // Payment Method field
                GestureDetector(
                  onTap: _showPaymentMethodDialog,
                  child: CustomTextField(
                    titleText: 'Payment Method',
                    controller: _paymentMethodController,
                    hintText: 'Select Payment Method',
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
                
                SizedBox(height: spacing),
                
                // Cheque Number and Date fields (only visible if Payment Method is cheque)
                if (_paymentDetails.paymentMethodKey == PaymentMethod.cheque) ...[
                  CustomTextField(
                    titleText: 'Cheque Number',
                    controller: _chequeNumberController,
                    hintText: 'Enter cheque number',
                    isMandatory: true,
                    borderRadius: 6,
                    maxLength: 6,
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        _paymentDetails = _paymentDetails.copyWith(chequeNumber: value);
                      });
                    },
                  ),
                  
                  SizedBox(height: spacing),
                  
                  GestureDetector(
                    onTap: _showDatePicker,
                    child: CustomTextField(
                      titleText: 'Cheque Date',
                      controller: _chequeDateController,
                      hintText: 'Select cheque date',
                      isMandatory: true,
                      borderRadius: 6,
                      enabled: false,
                      suffixIcon: const Icon(
                        Icons.calendar_today,
                        color: AppColors.lightGreyColor,
                        size: 20,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: spacing),
                  _buildChequeImageUploadSection(),
                  SizedBox(height: spacing),
                ],
                
                // Payment Type field
                GestureDetector(
                  onTap: _showPaymentTypeDialog,
                  child: CustomTextField(
                    titleText: 'Payment Type',
                    controller: _paymentTypeController,
                    hintText: 'Select Payment Type',
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
                
                // PAN Number field
                CustomTextField(
                  titleText: 'PAN Number',
                  controller: _panNumberController,
                  hintText: 'Enter PAN number',
                  isMandatory: false,
                  borderRadius: 6,
                  maxLength: 10,
                  onChanged: (value) {
                    setState(() {
                      _paymentDetails = _paymentDetails.copyWith(panNumber: value);
                    });
                  },
                ),
                
                SizedBox(height: spacing),
                
                // Aadhar Number field
                CustomTextField(
                  titleText: 'Aadhar Number',
                  controller: _aadharNumberController,
                  hintText: 'Enter Aadhar number',
                  isMandatory: true,
                  borderRadius: 6,
                  maxLength: 12,
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      _paymentDetails = _paymentDetails.copyWith(aadharNumber: value);
                    });
                  },
                ),
                
                SizedBox(height: spacing),
                
                // Salaried Individual checkbox (only visible if Payment Type is Finance)
                if (_selectedPaymentTypeKey == PaymentType.finance) ...[
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Checkbox(
                        value: _paymentDetails.isSalariedIndividual,
                        onChanged: (value) {
                          setState(() {
                            _paymentDetails = _paymentDetails.copyWith(
                              isSalariedIndividual: value ?? false,
                            );
                          });
                        },
                        activeColor: AppColors.textFieldBGColor,
                        checkColor: AppColors.primaryColor,
                        fillColor: WidgetStateProperty.resolveWith<Color>(
                              (Set<WidgetState> states) {
                          if (states.contains(WidgetState.selected)) {
                            return AppColors.textFieldBGColor;
                          }
                          return Colors.white;
                        },
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        side: WidgetStateBorderSide.resolveWith(
                              (Set<WidgetState> states) {
                          if (states.contains(WidgetState.selected)) {
                            return const BorderSide(color: AppColors.dropDownBorderColor, width: 1.5);
                          }
                          return const BorderSide(color: AppColors.dropDownBorderColor, width: 1);
                        },
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Salaried Individual',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.headingTextColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
                /*
                // Salary Slip field (only visible if Salaried Individual is checked)
                if (_paymentDetails.isSalariedIndividual) ...[
                  PdfUploadWidget(
                    label: 'Salary Slip',
                    fileName: _paymentDetails.salarySlipPath,
                    isRequired: false,
                    uploadUrl: '/api/documents/upload/',
                    placeholderText: 'Upload salary slip (PDF only)',
                    onFileSelected: (filePath) {
                      setState(() {
                        _paymentDetails = _paymentDetails.copyWith(salarySlipPath: filePath);
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Form 16A field
                  PdfUploadWidget(
                    label: 'Form 16A',
                    fileName: _paymentDetails.form16APath?.split('/').last,
                    isRequired: false,
                    uploadUrl: '/api/documents/upload/',
                    placeholderText: 'Upload form 16A for reference',
                    onFileSelected: (filePath) {
                      setState(() {
                        _paymentDetails = _paymentDetails.copyWith(form16APath: filePath);
                      });
                    },
                  ),
                  SizedBox(height: spacing),
                ],
                */
                // Additional Notes field
                CustomTextField(
                  titleText: 'Additional Notes',
                  controller: _additionalNotesController,
                  hintText: 'Enter any additional notes or special instructions',
                  isMandatory: false,
                  maxLines: 3,
                  borderRadius: 6,
                  maxLength: 150,
                  onChanged: (value) {
                    setState(() {
                      _paymentDetails = _paymentDetails.copyWith(additionalNotes: value);
                    });
                  },
                ),

              ],
            ),
          
          SizedBox(height: largeSpacing),
          
          // Action buttons
          ActionButtons(
            onPrevious: widget.onPrevious,
            onNext: _canProceed() ? () => widget.onNext?.call(_paymentDetails) : null,
            isPreviousEnabled: widget.onPrevious != null,
            isNextEnabled: _canProceed(),
            nextButtonText: widget.nextButtonText,
          ),
          
          SizedBox(height: kIsWeb ? 20 : 20),
        ],
      ),
    );
  }

  bool _canProceed() {
    // Payment Method is mandatory
    if (_paymentDetails.paymentMethodKey.isEmpty) return false;

    // Aadhaar number is mandatory
    if (_aadharNumberController.text.trim().isEmpty) return false;

    if (_paymentDetails.paymentMethodKey == PaymentMethod.cheque) {
      return _chequeNumberController.text.trim().isNotEmpty &&
          _paymentDetails.chequeDate != null &&
          (_paymentDetails.chequeImageBytes?.isNotEmpty ?? false);
    }

    return true;
  }

  void _showPaymentMethodDialog() {
    showDialog(
      context: context,
      builder: (context) => PaymentMethodSelectionDialog(
        title: 'Select Payment Method',
        options: PaymentMethod.all,
        selectedKey: _paymentDetails.paymentMethodKey,
        onSelected: (key, value) {
          setState(() {
            _paymentDetails = _paymentDetails.copyWith(
              paymentMethodKey: key,
              paymentMethod: value,
              // Clear cheque fields if payment method is not cheque
              chequeNumber: key == PaymentMethod.cheque ? _paymentDetails.chequeNumber : null,
              chequeDate: key == PaymentMethod.cheque ? _paymentDetails.chequeDate : null,
              chequeImageName: key == PaymentMethod.cheque ? _paymentDetails.chequeImageName : null,
              chequeImageBytes: key == PaymentMethod.cheque ? _paymentDetails.chequeImageBytes : null,
            );
            _paymentMethodController.text = value;
            
            // Clear cheque controllers if payment method is not cheque
            if (key != PaymentMethod.cheque) {
              _chequeNumberController.clear();
              _chequeDateController.clear();
            }
          });
        },
      ),
    );
  }

  void _showPaymentTypeDialog() {
    showDialog(
      context: context,
      builder: (context) => PaymentMethodSelectionDialog(
        title: 'Select Payment Type',
        options: PaymentType.all,
        selectedKey: _selectedPaymentTypeKey,
        onSelected: (key, value) {
          setState(() {
            _selectedPaymentTypeKey = key;
            _paymentDetails = _paymentDetails.copyWith(
              paymentType: value,
              paymentTypeKey: key,
              isSalariedIndividual: false, // Reset when changing payment type
            );
            _paymentTypeController.text = value;
          });
        },
      ),
    );
  }

  void _showDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _paymentDetails.chequeDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _paymentDetails = _paymentDetails.copyWith(chequeDate: picked);
        _chequeDateController.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  Widget _buildChequeImageUploadSection() {
    final hasChequeImage = _paymentDetails.chequeImageBytes != null && _paymentDetails.chequeImageBytes!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: kIsWeb ? 15 : 14,
              fontWeight: FontWeight.w600,
              color: AppColors.headingTextColor,
            ),
            children: const [
              TextSpan(text: 'Cheque Image '),
              TextSpan(
                text: '*',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _showChequeImageSourceDialog,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.textFieldBGColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.dropDownBorderColor),
            ),
            child: hasChequeImage
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          Uint8List.fromList(_paymentDetails.chequeImageBytes!),
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _showChequeImageSourceDialog,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Replace Image'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.camera_alt_outlined,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Upload cheque image',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.headingTextColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Take a photo or choose one from the gallery',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.headingTextColor.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.upload,
                        color: AppColors.primaryColor,
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  void _showChequeImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Cheque Image'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primaryColor),
              title: const Text('Camera'),
              subtitle: const Text('Capture image from camera'),
              onTap: () {
                Navigator.of(context).pop();
                Future.microtask(() => _pickChequeImage(ImageSource.camera));
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primaryColor),
              title: const Text('Gallery'),
              subtitle: const Text('Select image from gallery'),
              onTap: () {
                Navigator.of(context).pop();
                Future.microtask(() => _pickChequeImage(ImageSource.gallery));
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickChequeImage(ImageSource source) async {
    try {
      final pickedImage = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (pickedImage == null) return;

      final imageBytes = await pickedImage.readAsBytes();
      if (!mounted) return;

      setState(() {
        _paymentDetails = _paymentDetails.copyWith(
          chequeImageName: pickedImage.name,
          chequeImageBytes: imageBytes,
        );
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick cheque image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}