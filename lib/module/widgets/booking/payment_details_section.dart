import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
          ? '${widget.initialPaymentDetails!.chequeDate!.day}/${widget.initialPaymentDetails!.chequeDate!.month}/${widget.initialPaymentDetails!.chequeDate!.year}'
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
    final spacing = kIsWeb ? 28.0 : 24.0;
    final largeSpacing = kIsWeb ? 48.0 : 40.0;
    
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: kIsWeb ? 24 : 20,
        bottom: kIsWeb ? 36 : 32,
      ),
      child: Column(
        children: [
          SizedBox(height: kIsWeb ? 24 : 20),
          
          // Header with icon
          HeaderIconWidget(
            icon: IconsAssets.cardIcon,
            title: 'Payment Details',
            subtitle: 'Enter payment information',
          ),
          
          SizedBox(height: largeSpacing),
          
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
                _paymentDetails = _paymentDetails.copyWith(paymentAmount: value);
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
          
         
          
          // Cheque Number and Date fields (only visible if Payment Method is cheque)
          if (_paymentDetails.paymentMethodKey == PaymentMethod.cheque) ...[
            CustomTextField(
              titleText: 'Cheque Number',
              controller: _chequeNumberController,
              hintText: 'Enter cheque number',
              isMandatory: false,
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
                isMandatory: false,
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
            isMandatory: false,
            borderRadius: 6,
            maxLength: 12,
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                _paymentDetails = _paymentDetails.copyWith(aadharNumber: value);
              });
            },
          ),
          
          SizedBox(height: kIsWeb ? 24 : 20),
          
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
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // 👈 removes default padding
                  visualDensity: VisualDensity.compact, // 👈 tightens layout
                ),
                const SizedBox(width: 4), // optional spacing
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
          
          // Salary Slip field (only visible if Salaried Individual is checked)
          if (_paymentDetails.isSalariedIndividual) ...[
            PdfUploadWidget(
              label: 'Salary Slip',
              fileName: _paymentDetails.salarySlipPath,
              isRequired: false,
              uploadUrl: '/api/documents/upload/', // Replace with actual API endpoint
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
             // acceptedFileTypes: ['pdf', 'jpg', 'jpeg', 'png'],
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
          
          SizedBox(height: largeSpacing),
          
          // Action buttons
          ActionButtons(
            onPrevious: widget.onPrevious,
            onNext: _canProceed() ? () => widget.onNext?.call(_paymentDetails) : null,
            isPreviousEnabled: widget.onPrevious != null,
            isNextEnabled: _canProceed(),
            nextButtonText: widget.nextButtonText,
          ),
          
          SizedBox(height: kIsWeb ? 36 : 32),
        ],
      ),
    );
  }

  bool _canProceed() {
    // All fields are optional, so the user can always proceed
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
        _chequeDateController.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }
}