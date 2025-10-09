import 'package:flutter/material.dart';
import '../../../data/models/payment_model.dart';
import '../../../config/constant/app_colors.dart';
import '../../global/widgets/custom_text_field.dart';
import 'header_icon_widget.dart';
import 'file_upload_widget.dart';
import 'payment_selection_dialog.dart';
import 'action_buttons.dart';

class PaymentDetailsSection extends StatefulWidget {
  final String title;
  final String paymentAmount;
  final VoidCallback? onPrevious;
  final Function(PaymentDetails?)? onNext;
  final String? nextButtonText;

  const PaymentDetailsSection({
    super.key,
    required this.title,
    required this.paymentAmount,
    this.onPrevious,
    this.onNext,
    this.nextButtonText,
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

  @override
  void initState() {
    super.initState();
    _paymentDetails = PaymentDetails(
      paymentAmount: widget.paymentAmount,
      paymentMethod: '',
      paymentType: '',
      panNumber: '',
      aadharNumber: '',
      additionalNotes: '',
    );
    
    _paymentAmountController = TextEditingController(text: widget.paymentAmount);
    _panNumberController = TextEditingController();
    _aadharNumberController = TextEditingController();
    _additionalNotesController = TextEditingController();
  }

  @override
  void dispose() {
    _paymentAmountController.dispose();
    _panNumberController.dispose();
    _aadharNumberController.dispose();
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
            icon: Icons.credit_card,
            title: 'Payment Details',
            subtitle: 'Enter payment information',
          ),
          
          const SizedBox(height: 40),
          
          // Payment Amount field
          CustomTextField(
            titleText: 'Payment Amount',
            controller: _paymentAmountController,
            isMandatory: true,
            keyboardType: TextInputType.number,
            hintText: 'Enter Payment Amount',
            borderRadius: 6,
            onChanged: (value) {
              setState(() {
                _paymentDetails = _paymentDetails.copyWith(paymentAmount: value);
              });
            },
          ),
          
          const SizedBox(height: 24),
          
          // Payment Method field
          GestureDetector(
            onTap: _showPaymentMethodDialog,
            child: CustomTextField(
              titleText: 'Payment Method',
              hintText: _paymentDetails.paymentMethod.isNotEmpty 
                  ? _paymentDetails.paymentMethod 
                  : 'Select Payment Method',
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
          
          // Payment Type field
          GestureDetector(
            onTap: _showPaymentTypeDialog,
            child: CustomTextField(
              titleText: 'Payment Type',
              hintText: _paymentDetails.paymentType.isNotEmpty 
                  ? _paymentDetails.paymentType 
                  : 'Select Payment Type',
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
          
          // PAN Number field
          CustomTextField(
            titleText: 'PAN Number',
            controller: _panNumberController,
            hintText: 'Enter PAN number',
            isMandatory: true,
            borderRadius: 6,
            onChanged: (value) {
              setState(() {
                _paymentDetails = _paymentDetails.copyWith(panNumber: value);
              });
            },
          ),
          
          const SizedBox(height: 24),
          
          // Aadhar Number field
          CustomTextField(
            titleText: 'Aadhar Number',
            controller: _aadharNumberController,
            hintText: 'Enter Aadhar number',
            isMandatory: true,
            borderRadius: 6,
            onChanged: (value) {
              setState(() {
                _paymentDetails = _paymentDetails.copyWith(aadharNumber: value);
              });
            },
          ),
          
          const SizedBox(height: 20),
          
          // Salaried Individual checkbox (only visible if Payment Type is Loan)
          if (_paymentDetails.paymentType == PaymentType.loan) ...[
            Row(
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
                  activeColor: const Color.fromARGB(229, 171, 171, 171),
                  checkColor: Colors.red,
                  fillColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
                    return Colors.transparent;
                  }),
                  side: const BorderSide(color: Colors.grey, width: 1),
                ),
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
            FileUploadWidget(
              label: 'Salary Slip',
              fileName: _paymentDetails.salarySlipPath != null 
                  ? _paymentDetails.salarySlipPath!.split('/').last 
                  : null,
              isRequired: true,
              acceptedFileTypes: 'PDF, JPG, PNG',
              placeholderText: 'Upload salary slip for reference',
              onFileSelected: (filePath) {
                setState(() {
                  _paymentDetails = _paymentDetails.copyWith(salarySlipPath: filePath);
                });
              },
            ),
            const SizedBox(height: 24),
            
            // Form 16A field
            FileUploadWidget(
              label: 'Form 16A',
              fileName: _paymentDetails.form16APath != null 
                  ? _paymentDetails.form16APath!.split('/').last 
                  : null,
              isRequired: true,
              acceptedFileTypes: 'PDF, JPG, PNG',
              placeholderText: 'Upload form 16A for reference',
              onFileSelected: (filePath) {
                setState(() {
                  _paymentDetails = _paymentDetails.copyWith(form16APath: filePath);
                });
              },
            ),
            const SizedBox(height: 24),
          ],
          
          // Additional Notes field
          CustomTextField(
            titleText: 'Additional Notes',
            controller: _additionalNotesController,
            hintText: 'Enter any additional notes or special instructions',
            isMandatory: true,
            maxLines: 3,
            borderRadius: 6,
            onChanged: (value) {
              setState(() {
                _paymentDetails = _paymentDetails.copyWith(additionalNotes: value);
              });
            },
          ),
          
          const SizedBox(height: 40),
          
          // Action buttons
          ActionButtons(
            onPrevious: widget.onPrevious,
            onNext: _canProceed() ? () => widget.onNext?.call(_paymentDetails) : null,
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
    // Basic validation
    if (_paymentDetails.paymentAmount.isEmpty ||
        _paymentDetails.paymentMethod.isEmpty ||
        _paymentDetails.paymentType.isEmpty ||
        _paymentDetails.panNumber.isEmpty ||
        _paymentDetails.aadharNumber.isEmpty ||
        _paymentDetails.additionalNotes.isEmpty) {
      return false;
    }
    
    // Additional validation for salaried individual
    if (_paymentDetails.isSalariedIndividual) {
      if (_paymentDetails.salarySlipPath == null || _paymentDetails.form16APath == null) {
        return false;
      }
    }
    
    return true;
  }

  void _showPaymentMethodDialog() {
    showDialog(
      context: context,
      builder: (context) => PaymentSelectionDialog(
        title: 'Select Payment Method',
        options: PaymentMethod.all,
        selectedValue: _paymentDetails.paymentMethod,
        onSelected: (method) {
          setState(() {
            _paymentDetails = _paymentDetails.copyWith(paymentMethod: method);
          });
        },
      ),
    );
  }

  void _showPaymentTypeDialog() {
    showDialog(
      context: context,
      builder: (context) => PaymentSelectionDialog(
        title: 'Select Payment Type',
        options: PaymentType.all,
        selectedValue: _paymentDetails.paymentType,
        onSelected: (type) {
          setState(() {
            _paymentDetails = _paymentDetails.copyWith(
              paymentType: type,
              isSalariedIndividual: false, // Reset when changing payment type
            );
          });
        },
      ),
    );
  }
}
