import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../../../config/constant/const_assets.dart';
import '../../../data/models/payment_model.dart';
import '../../../config/constant/app_colors.dart';
import '../../../services/cheque_analysis_service.dart';
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
  final double? saleableSize;
  final bool plcApplied;
  final double? plcPercentage;
  final String? pricePerSqYd;

  /// Pre-computed total for multi-plot bookings. When provided, this value is
  /// used as the initial total amount instead of computing from price × size.
  final String? precomputedTotalAmount;

  /// When set (from project pay_name), AI verifies the cheque payee matches this name.
  final String? expectedPayName;

  /// When true, plot price/total are not prefilled or submitted.
  final bool hidePlotPricing;

  const PaymentDetailsSection({
    super.key,
    required this.title,
    required this.paymentAmount,
    this.onPrevious,
    this.onNext,
    this.nextButtonText,
    this.initialPaymentDetails,
    this.saleableSize,
    this.plcApplied = false,
    this.plcPercentage,
    this.pricePerSqYd,
    this.precomputedTotalAmount,
    this.expectedPayName,
    this.hidePlotPricing = false,
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
  late TextEditingController _bankController;
  late TextEditingController _loanAmountController;
  late TextEditingController _pricePerSqYdController;
  late TextEditingController _totalAmountController;
  late TextEditingController _upiTransactionIdController;
  final ImagePicker _imagePicker = ImagePicker();
  final ChequeAnalysisService _chequeAnalysisService = ChequeAnalysisService();
  String _selectedPaymentTypeKey = '';
  bool _isAnalyzingCheque = false;
  ChequeInfo? _chequeInfo;
  // When true, user has chosen to skip AI and enter cheque details manually
  bool _chequeManualOverride = false;
  List<int>? _lastChequeImageBytes; // kept for retry
  // When true, the cheque image was pre-loaded from initialPaymentDetails
  // (already AI-verified in a prior step), so the AI check can be skipped
  bool _chequePreloaded = false;

  @override
  void initState() {
    super.initState();
    // Initialize with provided payment details if available, otherwise use defaults
    if (widget.initialPaymentDetails != null) {
      _paymentDetails = widget.initialPaymentDetails!;
      if (_paymentDetails.paymentTypeKey.isEmpty) {
        _paymentDetails = _paymentDetails.copyWith(
          paymentTypeKey: PaymentType.oneTime,
          paymentType: PaymentType.getValue(PaymentType.oneTime),
        );
      }
      _selectedPaymentTypeKey = _paymentDetails.paymentTypeKey;
    } else {
      _paymentDetails = PaymentDetails(
        paymentAmount: '',
        paymentMethod: '',
        paymentMethodKey: '',
        paymentType: PaymentType.getValue(PaymentType.oneTime),
        paymentTypeKey: PaymentType.oneTime,
        panNumber: '',
        aadharNumber: '',
        additionalNotes: '',
        chequeImageName: null,
        chequeImageBytes: null,
        rtgsImageName: null,
        rtgsImageBytes: null,
      );
      _selectedPaymentTypeKey = PaymentType.oneTime;
    }

    _paymentAmountController = TextEditingController(
      text: widget.initialPaymentDetails?.paymentAmount ?? '',
    );
    _panNumberController = TextEditingController(
      text: widget.initialPaymentDetails?.panNumber ?? '',
    );
    _aadharNumberController = TextEditingController(
      text: widget.initialPaymentDetails?.aadharNumber ?? '',
    );
    _additionalNotesController = TextEditingController(
      text: widget.initialPaymentDetails?.additionalNotes ?? '',
    );
    _paymentMethodController = TextEditingController(
      text: widget.initialPaymentDetails?.paymentMethod ?? '',
    );
    _paymentTypeController = TextEditingController(
      text: _paymentDetails.paymentType,
    );
    _chequeNumberController = TextEditingController(
      text: widget.initialPaymentDetails?.chequeNumber ?? '',
    );
    _chequeDateController = TextEditingController(
      text: widget.initialPaymentDetails?.chequeDate != null
          ? '${widget.initialPaymentDetails!.chequeDate!.day.toString().padLeft(2, '0')}/${widget.initialPaymentDetails!.chequeDate!.month.toString().padLeft(2, '0')}/${widget.initialPaymentDetails!.chequeDate!.year}'
          : '',
    );
    _bankController = TextEditingController(
      text: widget.initialPaymentDetails?.loanBankName ?? '',
    );
    _loanAmountController = TextEditingController(
      text: widget.initialPaymentDetails?.loanAmount ?? '',
    );
    final resolvedPricePerSqYd = widget.hidePlotPricing
        ? ''
        : ((widget.initialPaymentDetails?.pricePerSqYd.isNotEmpty == true)
              ? widget.initialPaymentDetails!.pricePerSqYd
              : (widget.pricePerSqYd ?? ''));
    _pricePerSqYdController = TextEditingController(text: resolvedPricePerSqYd);
    final initialPrice = resolvedPricePerSqYd;
    final computedTotal = widget.hidePlotPricing
        ? ''
        : _computeTotalAmount(initialPrice);
    // For multi-plot bookings a pre-computed total is passed in directly.
    final initialTotal = widget.hidePlotPricing
        ? ''
        : ((widget.precomputedTotalAmount?.isNotEmpty == true)
              ? widget.precomputedTotalAmount!
              : computedTotal);
    _totalAmountController = TextEditingController(
      text: widget.hidePlotPricing
          ? ''
          : (widget.initialPaymentDetails?.totalAmount.isNotEmpty == true
                ? widget.initialPaymentDetails!.totalAmount
                : initialTotal),
    );
    if (!widget.hidePlotPricing &&
        resolvedPricePerSqYd.isNotEmpty &&
        (widget.initialPaymentDetails?.pricePerSqYd ?? '').isEmpty) {
      _paymentDetails = _paymentDetails.copyWith(
        pricePerSqYd: resolvedPricePerSqYd,
      );
    }
    if (!widget.hidePlotPricing &&
        initialTotal.isNotEmpty &&
        (widget.initialPaymentDetails?.totalAmount ?? '').isEmpty) {
      _paymentDetails = _paymentDetails.copyWith(totalAmount: initialTotal);
    }
    _upiTransactionIdController = TextEditingController(
      text: widget.initialPaymentDetails?.upiTransactionId ?? '',
    );

    // If initial data already has cheque bytes, the image was previously AI-verified
    if (widget.initialPaymentDetails?.chequeImageBytes?.isNotEmpty == true) {
      _chequePreloaded = true;
    }
  }

  String _computeTotalAmount(String priceText) {
    final price = double.tryParse(priceText.trim());
    //final size = widget.saleableSize;
    if (price == null) return '';
    double effectivePrice = price;
    if (widget.plcApplied &&
        widget.plcPercentage != null &&
        widget.plcPercentage! > 0) {
      effectivePrice = price * (1 + widget.plcPercentage! / 100);
    }
    final total = effectivePrice;
    return total % 1 == 0 ? total.toStringAsFixed(0) : total.toStringAsFixed(2);
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
    _bankController.dispose();
    _loanAmountController.dispose();
    _pricePerSqYdController.dispose();
    _totalAmountController.dispose();
    _upiTransactionIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = kIsWeb ? 24.0 : 24.0;
    final largeSpacing = kIsWeb ? 40.0 : 40.0;

    return SingleChildScrollView(
      padding: EdgeInsets.only(top: kIsWeb ? 20 : 20, bottom: kIsWeb ? 20 : 20),
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
                      titleText: 'Booking Amount',
                      controller: _paymentAmountController,
                      isMandatory: true,
                      keyboardType: TextInputType.number,
                      hintText: 'Enter Booking Amount',
                      borderRadius: 8,
                      onChanged: (value) {
                        setState(() {
                          _paymentDetails = _paymentDetails.copyWith(
                            paymentAmount: value,
                          );
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

                    // Cheque image upload (only visible if Payment Method is cheque)
                    if (_paymentDetails.paymentMethodKey ==
                        PaymentMethod.cheque) ...[
                      _buildChequeImageUploadSection(),
                      SizedBox(height: spacing),
                    ],

                    // RTGS slip upload (only visible if Payment Method is RTGS/NEFT)
                    if (_paymentDetails.paymentMethodKey ==
                        PaymentMethod.rtgs) ...[
                      _buildRtgsImageUploadSection(),
                      SizedBox(height: spacing),
                    ],

                    // UPI Transaction ID (only visible if Payment Method is UPI)
                    if (_paymentDetails.paymentMethodKey ==
                        PaymentMethod.upi) ...[
                      CustomTextField(
                        titleText: 'UPI Transaction ID',
                        controller: _upiTransactionIdController,
                        isMandatory: true,
                        hintText: 'Enter UPI Transaction ID',
                        borderRadius: 8,
                        onChanged: (value) {
                          setState(() {
                            _paymentDetails = _paymentDetails.copyWith(
                              upiTransactionId: value,
                            );
                          });
                        },
                      ),
                      SizedBox(height: spacing),
                    ],

                    // Payment Type radio group (full width)
                    _buildPaymentTypeRadioGroup(borderRadius: 8),

                    // Select Bank and Loan Amount fields (only visible when Payment Type is With Loan)
                    if (_selectedPaymentTypeKey == PaymentType.finance) ...[
                      SizedBox(height: spacing),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: _showBankSelectionDialog,
                              child: CustomTextField(
                                titleText: 'Select Bank',
                                controller: _bankController,
                                hintText: 'Select Loan Bank',
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
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: CustomTextField(
                              titleText: 'Loan Amount',
                              controller: _loanAmountController,
                              hintText: 'Enter Loan Amount',
                              isMandatory: false,
                              borderRadius: 8,
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                setState(() {
                                  _paymentDetails = _paymentDetails.copyWith(
                                    loanAmount: value,
                                  );
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],

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
                                _paymentDetails = _paymentDetails.copyWith(
                                  panNumber: value,
                                );
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
                            isMandatory: false,
                            borderRadius: 8,
                            maxLength: 12,
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setState(() {
                                _paymentDetails = _paymentDetails.copyWith(
                                  aadharNumber: value,
                                );
                              });
                            },
                          ),
                        ),
                      ],
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
                            fillColor: WidgetStateProperty.resolveWith<Color>((
                              Set<WidgetState> states,
                            ) {
                              if (states.contains(WidgetState.selected)) {
                                return AppColors.textFieldBGColor;
                              }
                              return Colors.white;
                            }),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            side: WidgetStateBorderSide.resolveWith((
                              Set<WidgetState> states,
                            ) {
                              if (states.contains(WidgetState.selected)) {
                                return const BorderSide(
                                  color: AppColors.dropDownBorderColor,
                                  width: 1.5,
                                );
                              }
                              return const BorderSide(
                                color: AppColors.dropDownBorderColor,
                                width: 1,
                              );
                            }),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
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
                            _paymentDetails = _paymentDetails.copyWith(
                              salarySlipPath: filePath,
                            );
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
                            _paymentDetails = _paymentDetails.copyWith(
                              form16APath: filePath,
                            );
                          });
                        },
                      ),
                      SizedBox(height: spacing),
                    ],

                    // Additional Notes field (full width)
                    CustomTextField(
                      titleText: 'Additional Notes',
                      controller: _additionalNotesController,
                      hintText:
                          'Enter any additional notes or special instructions',
                      isMandatory: false,
                      maxLines: 3,
                      borderRadius: 8,
                      maxLength: 150,
                      onChanged: (value) {
                        setState(() {
                          _paymentDetails = _paymentDetails.copyWith(
                            additionalNotes: value,
                          );
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
                  titleText: 'Booking Amount',
                  controller: _paymentAmountController,
                  isMandatory: true,
                  keyboardType: TextInputType.number,
                  hintText: 'Enter Booking Amount',
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

                // Cheque image upload (only visible if Payment Method is cheque)
                if (_paymentDetails.paymentMethodKey ==
                    PaymentMethod.cheque) ...[
                  _buildChequeImageUploadSection(),
                  SizedBox(height: spacing),
                ],

                // RTGS slip upload (only visible if Payment Method is RTGS/NEFT)
                if (_paymentDetails.paymentMethodKey == PaymentMethod.rtgs) ...[
                  _buildRtgsImageUploadSection(),
                  SizedBox(height: spacing),
                ],

                // UPI Transaction ID (only visible if Payment Method is UPI)
                if (_paymentDetails.paymentMethodKey == PaymentMethod.upi) ...[
                  CustomTextField(
                    titleText: 'UPI Transaction ID',
                    controller: _upiTransactionIdController,
                    isMandatory: true,
                    hintText: 'Enter UPI Transaction ID',
                    borderRadius: 6,
                    onChanged: (value) {
                      setState(() {
                        _paymentDetails = _paymentDetails.copyWith(
                          upiTransactionId: value,
                        );
                      });
                    },
                  ),
                  SizedBox(height: spacing),
                ],

                // Payment Type radio group
                _buildPaymentTypeRadioGroup(borderRadius: 6),

                // Select Bank and Loan Amount fields (only visible when Payment Type is With Loan)
                if (_selectedPaymentTypeKey == PaymentType.finance) ...[
                  SizedBox(height: spacing),
                  GestureDetector(
                    onTap: _showBankSelectionDialog,
                    child: CustomTextField(
                      titleText: 'Select Bank',
                      controller: _bankController,
                      hintText: 'Select Loan Bank',
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
                  CustomTextField(
                    titleText: 'Loan Amount',
                    controller: _loanAmountController,
                    hintText: 'Enter Loan Amount',
                    isMandatory: false,
                    borderRadius: 6,
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        _paymentDetails = _paymentDetails.copyWith(
                          loanAmount: value,
                        );
                      });
                    },
                  ),
                ],

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
                      _paymentDetails = _paymentDetails.copyWith(
                        panNumber: value,
                      );
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
                      _paymentDetails = _paymentDetails.copyWith(
                        aadharNumber: value,
                      );
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
                        fillColor: WidgetStateProperty.resolveWith<Color>((
                          Set<WidgetState> states,
                        ) {
                          if (states.contains(WidgetState.selected)) {
                            return AppColors.textFieldBGColor;
                          }
                          return Colors.white;
                        }),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        side: WidgetStateBorderSide.resolveWith((
                          Set<WidgetState> states,
                        ) {
                          if (states.contains(WidgetState.selected)) {
                            return const BorderSide(
                              color: AppColors.dropDownBorderColor,
                              width: 1.5,
                            );
                          }
                          return const BorderSide(
                            color: AppColors.dropDownBorderColor,
                            width: 1,
                          );
                        }),
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
                        _paymentDetails = _paymentDetails.copyWith(
                          salarySlipPath: filePath,
                        );
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
                        _paymentDetails = _paymentDetails.copyWith(
                          form16APath: filePath,
                        );
                      });
                    },
                  ),
                  SizedBox(height: spacing),
                ],

                // Additional Notes field
                CustomTextField(
                  titleText: 'Additional Notes',
                  controller: _additionalNotesController,
                  hintText:
                      'Enter any additional notes or special instructions',
                  isMandatory: false,
                  maxLines: 3,
                  borderRadius: 6,
                  maxLength: 150,
                  onChanged: (value) {
                    setState(() {
                      _paymentDetails = _paymentDetails.copyWith(
                        additionalNotes: value,
                      );
                    });
                  },
                ),
              ],
            ),

          SizedBox(height: largeSpacing),

          // Action buttons
          ActionButtons(
            onPrevious: widget.onPrevious,
            onNext: _canProceed()
                ? () {
                    final details = widget.hidePlotPricing
                        ? _paymentDetails.copyWith(
                            pricePerSqYd: '',
                            totalAmount: '',
                          )
                        : _paymentDetails;
                    widget.onNext?.call(details);
                  }
                : null,
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
    // Booking Amount is mandatory
    if (_paymentAmountController.text.trim().isEmpty) return false;

    // Payment Method is mandatory
    if (_paymentDetails.paymentMethodKey.isEmpty) return false;


    if (_aadharNumberController.text.trim().isNotEmpty && _aadharNumberController.text.trim().length < 12) return false;

    if (_paymentDetails.paymentMethodKey == PaymentMethod.cheque) {
      // Cannot proceed while Gemini is still analyzing
      if (_isAnalyzingCheque) return false;

      final hasNewChequeImage =
          _paymentDetails.chequeImageBytes?.isNotEmpty ?? false;
      final hasExistingChequeImage =
          _paymentDetails.existingChequeImageUrl?.isNotEmpty ?? false;

      if (!hasNewChequeImage && !hasExistingChequeImage) return false;

      if (hasNewChequeImage) {
        // Manual override: AI was unavailable, user entered cheque number themselves
        if (_chequeManualOverride) {
          return _chequeNumberController.text.trim().isNotEmpty;
        }
        // Image was pre-loaded from initialPaymentDetails (already AI-verified before)
        if (_chequePreloaded) return true;
        // AI must have confirmed it is a cheque with a readable cheque number
        if (_chequeInfo == null || !_chequeInfo!.isCheque) return false;
        if (_chequeNumberController.text.trim().isEmpty) return false;
      }

      return true;
    }

    if (_paymentDetails.paymentMethodKey == PaymentMethod.rtgs) {
      final hasNewRtgsImage =
          _paymentDetails.rtgsImageBytes?.isNotEmpty ?? false;
      final hasExistingRtgsImage =
          _paymentDetails.existingRtgsImageUrl?.isNotEmpty ?? false;
      return hasNewRtgsImage || hasExistingRtgsImage;
    }

    if (_paymentDetails.paymentMethodKey == PaymentMethod.upi) {
      return _upiTransactionIdController.text.trim().isNotEmpty;
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
              chequeNumber: key == PaymentMethod.cheque
                  ? _paymentDetails.chequeNumber
                  : null,
              chequeDate: key == PaymentMethod.cheque
                  ? _paymentDetails.chequeDate
                  : null,
              chequeImageName: key == PaymentMethod.cheque
                  ? _paymentDetails.chequeImageName
                  : null,
              chequeImageBytes: key == PaymentMethod.cheque
                  ? _paymentDetails.chequeImageBytes
                  : null,
              existingChequeImageUrl: key == PaymentMethod.cheque
                  ? _paymentDetails.existingChequeImageUrl
                  : null,
              rtgsImageName: key == PaymentMethod.rtgs
                  ? _paymentDetails.rtgsImageName
                  : null,
              rtgsImageBytes: key == PaymentMethod.rtgs
                  ? _paymentDetails.rtgsImageBytes
                  : null,
              existingRtgsImageUrl: key == PaymentMethod.rtgs
                  ? _paymentDetails.existingRtgsImageUrl
                  : null,
              upiTransactionId: key == PaymentMethod.upi
                  ? _paymentDetails.upiTransactionId
                  : null,
            );
            _paymentMethodController.text = value;

            if (key != PaymentMethod.cheque) {
              _chequeNumberController.clear();
              _chequeDateController.clear();
            }
            if (key != PaymentMethod.upi) {
              _upiTransactionIdController.clear();
            }
          });
        },
      ),
    );
  }

  void _onPaymentTypeSelected(String key, String value) {
    setState(() {
      _selectedPaymentTypeKey = key;
      final isLoan = key == PaymentType.finance;
      _paymentDetails = PaymentDetails(
        paymentAmount: _paymentDetails.paymentAmount,
        paymentMethod: _paymentDetails.paymentMethod,
        paymentMethodKey: _paymentDetails.paymentMethodKey,
        paymentType: value,
        paymentTypeKey: key,
        panNumber: _paymentDetails.panNumber,
        aadharNumber: _paymentDetails.aadharNumber,
        isSalariedIndividual: false,
        salarySlipPath: _paymentDetails.salarySlipPath,
        form16APath: _paymentDetails.form16APath,
        additionalNotes: _paymentDetails.additionalNotes,
        chequeNumber: _paymentDetails.chequeNumber,
        chequeDate: _paymentDetails.chequeDate,
        chequeImageName: _paymentDetails.chequeImageName,
        chequeImageBytes: _paymentDetails.chequeImageBytes,
        existingChequeImageUrl: _paymentDetails.existingChequeImageUrl,
        rtgsImageName: _paymentDetails.rtgsImageName,
        rtgsImageBytes: _paymentDetails.rtgsImageBytes,
        existingRtgsImageUrl: _paymentDetails.existingRtgsImageUrl,
        loanBankName: isLoan ? _paymentDetails.loanBankName : null,
        loanBankKey: isLoan ? _paymentDetails.loanBankKey : null,
        loanAmount: isLoan ? _paymentDetails.loanAmount : null,
        pricePerSqYd: _paymentDetails.pricePerSqYd,
        totalAmount: _paymentDetails.totalAmount,
        upiTransactionId: _paymentDetails.upiTransactionId,
      );
      _paymentTypeController.text = value;
      if (!isLoan) {
        _bankController.clear();
        _loanAmountController.clear();
      }
    });
  }

  Widget _buildPaymentTypeRadioGroup({double borderRadius = 8}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Type',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.headingTextColor,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: PaymentType.all.entries.map((entry) {
            final isSelected = _selectedPaymentTypeKey == entry.key;
            final isFirst = entry.key == PaymentType.oneTime;
            return Expanded(
              child: GestureDetector(
                onTap: () => _onPaymentTypeSelected(entry.key, entry.value),
                child: Container(
                  margin: EdgeInsets.only(right: isFirst ? 10 : 0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryColor.withValues(alpha: 0.07)
                        : AppColors.textFieldBGColor,
                    borderRadius: BorderRadius.circular(borderRadius),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryColor
                          : AppColors.lightGreyBorderColor,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Radio<String>(
                        value: entry.key,
                        groupValue: _selectedPaymentTypeKey,
                        activeColor: AppColors.primaryColor,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        onChanged: (val) {
                          if (val != null) {
                            _onPaymentTypeSelected(
                              val,
                              PaymentType.getValue(val),
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? AppColors.primaryColor
                                : AppColors.headingTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showBankSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => PaymentMethodSelectionDialog(
        title: 'Select Bank',
        options: IndianBanks.all,
        selectedKey: _paymentDetails.loanBankKey ?? '',
        onSelected: (key, value) {
          setState(() {
            _paymentDetails = _paymentDetails.copyWith(
              loanBankKey: key,
              loanBankName: value,
            );
            _bankController.text = value;
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
        _chequeDateController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  Widget _buildChequeImageUploadSection() {
    final hasNewChequeImage =
        _paymentDetails.chequeImageBytes != null &&
        _paymentDetails.chequeImageBytes!.isNotEmpty;
    final hasExistingChequeImage =
        _paymentDetails.existingChequeImageUrl != null &&
        _paymentDetails.existingChequeImageUrl!.isNotEmpty;
    final hasChequeImage = hasNewChequeImage || hasExistingChequeImage;

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
          onTap: _isAnalyzingCheque ? null : _showChequeImageSourceDialog,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.textFieldBGColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.dropDownBorderColor),
            ),
            child: _isAnalyzingCheque
                ? _buildAnalyzingLoader()
                : hasChequeImage
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: hasNewChequeImage
                            ? Image.memory(
                                Uint8List.fromList(
                                  _paymentDetails.chequeImageBytes!,
                                ),
                                width: double.infinity,
                                height: 180,
                                fit: BoxFit.cover,
                              )
                            : Image.network(
                                _paymentDetails.existingChequeImageUrl!,
                                width: double.infinity,
                                height: 180,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: double.infinity,
                                  height: 180,
                                  color: AppColors.textFieldBGColor,
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'Unable to load cheque image',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
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
                                color: AppColors.headingTextColor.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.upload, color: AppColors.primaryColor),
                    ],
                  ),
          ),
        ),

        // Gemini result cards
        if (!_isAnalyzingCheque && _chequeInfo != null) ...[
          const SizedBox(height: 12),
          if (_chequeInfo!.isCheque)
            // _buildChequeInfoCard(_chequeInfo!)
            Container()
          else if (_chequeInfo!.isServerError ||
              _chequeInfo!.status == ChequeAnalysisStatus.unknownError)
            _buildServerErrorCard(
              _chequeInfo!.errorMessage ?? 'AI is temporarily unavailable.',
            ),
        ],

        // Cheque number field — shown when image present and not analyzing
        if (hasChequeImage && !_isAnalyzingCheque) ...[
          // Manual override banner
          if (_chequeManualOverride) ...[
            const SizedBox(height: 12),
            _buildManualOverrideBanner(),
          ],
          const SizedBox(height: 16),
          CustomTextField(
            titleText: 'Cheque Number',
            controller: _chequeNumberController,
            isMandatory: _chequeManualOverride,
            hintText: _chequeManualOverride
                ? 'Enter cheque number manually'
                : 'Cheque number (auto-filled by AI)',
            borderRadius: kIsWeb ? 8 : 6,
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                _paymentDetails = _paymentDetails.copyWith(chequeNumber: value);
              });
            },
          ),
        ],
      ],
    );
  }

  Widget _buildServerErrorCard(String message) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFCD34D), width: 1.5),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFD97706),
                size: 18,
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'AI Verification Temporarily Unavailable',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(fontSize: 12, color: Color(0xFF78350F)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _lastChequeImageBytes != null
                      ? () async {
                          setState(() {
                            _isAnalyzingCheque = true;
                            _chequeInfo = null;
                          });
                          await _runChequeAnalysis(_lastChequeImageBytes!);
                        }
                      : null,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry AI', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD97706),
                    side: const BorderSide(color: Color(0xFFFCD34D)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _chequeManualOverride = true);
                  },
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text(
                    'Enter Manually',
                    style: TextStyle(fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManualOverrideBanner() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF7DD3FC)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF0284C7), size: 16),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Manual mode: Please enter the cheque number carefully.',
              style: TextStyle(fontSize: 12, color: Color(0xFF0369A1)),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _chequeManualOverride = false),
            child: const Icon(Icons.close, size: 16, color: Color(0xFF0284C7)),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzingLoader() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryColor,
                ),
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Analyzing Your Image...',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.headingTextColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Verifying cheque and extracting details',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.headingTextColor.withValues(alpha: 0.6),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildChequeInfoCard(ChequeInfo info) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 18),
              SizedBox(width: 6),
              Text(
                'Cheque Detected',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF15803D),
                ),
              ),
              Spacer(),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: Color(0xFFBBF7D0), height: 1),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (info.chequeNumber != null)
                _infoChip(Icons.tag, 'Cheque No', info.chequeNumber!),
              if (info.bankName != null)
                _infoChip(Icons.account_balance, 'Bank', info.bankName!),
              if (info.branchName != null)
                _infoChip(
                  Icons.location_on_outlined,
                  'Branch',
                  info.branchName!,
                ),
              if (info.date != null)
                _infoChip(Icons.calendar_today_outlined, 'Date', info.date!),
              if (info.amount != null)
                _infoChip(Icons.currency_rupee, 'Amount', info.amount!),
              if (info.payeeName != null)
                _infoChip(Icons.person_outline, 'Payee', info.payeeName!),
              if (info.drawerName != null)
                _infoChip(Icons.person_2_outlined, 'Drawer', info.drawerName!),
              if (info.accountNumber != null)
                _infoChip(
                  Icons.account_box_outlined,
                  'A/C No',
                  info.accountNumber!,
                ),
              if (info.ifscCode != null)
                _infoChip(Icons.code, 'IFSC', info.ifscCode!),
              if (info.micrCode != null)
                _infoChip(Icons.qr_code_outlined, 'MICR', info.micrCode!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF16A34A)),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
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
              leading: const Icon(
                Icons.camera_alt,
                color: AppColors.primaryColor,
              ),
              title: const Text('Camera'),
              subtitle: const Text('Capture image from camera'),
              onTap: () {
                Navigator.of(context).pop();
                Future.microtask(() => _pickChequeImage(ImageSource.camera));
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: AppColors.primaryColor,
              ),
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

      // Show loading state while Gemini analyzes the image
      setState(() {
        _isAnalyzingCheque = true;
        _chequeInfo = null;
        _chequeManualOverride = false;
        _chequePreloaded = false;
        _lastChequeImageBytes = imageBytes;
        _chequeNumberController.clear();
        _chequeDateController.clear();
        _paymentDetails = _paymentDetails.copyWith(
          chequeImageName: pickedImage.name,
          chequeImageBytes: imageBytes,
          existingChequeImageUrl: null,
          chequeNumber: null,
          chequeDate: null,
        );
      });

      await _runChequeAnalysis(imageBytes);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAnalyzingCheque = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick cheque image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String? get _effectiveExpectedPayName {
    final name = widget.expectedPayName?.trim();
    return (name != null && name.isNotEmpty) ? name : null;
  }

  Future<void> _runChequeAnalysis(List<int> imageBytes) async {
    final result = await _chequeAnalysisService.analyzeCheque(
      imageBytes,
      expectedPayName: _effectiveExpectedPayName,
    );
    if (!mounted) return;

    if (result.isNotACheque) {
      // Clearly not a cheque — clear image AND cheque number, block user
      setState(() {
        _isAnalyzingCheque = false;
        _chequeInfo = null;
        _chequeManualOverride = false;
        _lastChequeImageBytes = null;
        _chequeNumberController.clear();
        _chequeDateController.clear();
        _paymentDetails = _paymentDetails.copyWith(
          chequeImageName: null,
          chequeImageBytes: null,
          chequeNumber: null,
          chequeDate: null,
        );
      });
      _showNotChequeDialog(
        'The selected image does not appear to be a bank cheque.\nPlease upload a valid cheque image.',
      );
      return;
    }

    if (result.isChequeNumberUnreadable) {
      // Cheque is valid but cheque number is blurred/cropped — clear image AND cheque number, block user
      setState(() {
        _isAnalyzingCheque = false;
        _chequeInfo = null;
        _chequeManualOverride = false;
        _lastChequeImageBytes = null;
        _chequeNumberController.clear();
        _chequeDateController.clear();
        _paymentDetails = _paymentDetails.copyWith(
          chequeImageName: null,
          chequeImageBytes: null,
          chequeNumber: null,
          chequeDate: null,
        );
      });
      _showNotChequeDialog(
        result.errorMessage ??
            'Cheque number is not clearly visible.\n\nPlease make sure the bottom portion of the cheque is fully visible, not blurred or cropped, and upload again.',
      );
      return;
    }

    if (result.isPayNameMismatch) {
      setState(() {
        _isAnalyzingCheque = false;
        _chequeInfo = null;
        _chequeManualOverride = false;
        _lastChequeImageBytes = null;
        _chequeNumberController.clear();
        _chequeDateController.clear();
        _paymentDetails = _paymentDetails.copyWith(
          chequeImageName: null,
          chequeImageBytes: null,
          chequeNumber: null,
          chequeDate: null,
        );
      });
      _showNotChequeDialog(
        result.errorMessage ??
            'The payee name on the cheque does not match the required payee for this project.',
        title: 'Payee Name Mismatch',
      );
      return;
    }

    if (result.isServerError ||
        result.status == ChequeAnalysisStatus.unknownError) {
      // Server busy or unknown error — keep image, show retry/manual option
      setState(() {
        _isAnalyzingCheque = false;
        _chequeInfo = result; // store so UI can show retry card
      });
      return;
    }

    // Success — auto-fill fields
    setState(() {
      _isAnalyzingCheque = false;
      _chequeInfo = result;
      _chequeManualOverride = false;

      if (result.chequeNumber != null) {
        _chequeNumberController.text = result.chequeNumber!;
        _paymentDetails = _paymentDetails.copyWith(
          chequeNumber: result.chequeNumber,
        );
      }

      if (result.date != null) {
        _chequeDateController.text = result.date!;
        try {
          final parts = result.date!.split('/');
          if (parts.length == 3) {
            final parsed = DateTime(
              int.parse(parts[2]),
              int.parse(parts[1]),
              int.parse(parts[0]),
            );
            _paymentDetails = _paymentDetails.copyWith(chequeDate: parsed);
          }
        } catch (_) {}
      }
    });
  }

  void _showNotChequeDialog(String message, {String title = 'Not a Cheque'}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 24),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 18)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'OK',
              style: TextStyle(color: AppColors.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRtgsImageUploadSection() {
    final hasNewRtgsImage =
        _paymentDetails.rtgsImageBytes != null &&
        _paymentDetails.rtgsImageBytes!.isNotEmpty;
    final hasExistingRtgsImage =
        _paymentDetails.existingRtgsImageUrl != null &&
        _paymentDetails.existingRtgsImageUrl!.isNotEmpty;
    final hasRtgsImage = hasNewRtgsImage || hasExistingRtgsImage;

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
              TextSpan(text: 'RTGS Slip '),
              TextSpan(
                text: '*',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _showRtgsImageSourceDialog,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.textFieldBGColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.dropDownBorderColor),
            ),
            child: hasRtgsImage
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: hasNewRtgsImage
                            ? Image.memory(
                                Uint8List.fromList(
                                  _paymentDetails.rtgsImageBytes!,
                                ),
                                width: double.infinity,
                                height: 180,
                                fit: BoxFit.cover,
                              )
                            : Image.network(
                                _paymentDetails.existingRtgsImageUrl!,
                                width: double.infinity,
                                height: 180,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: double.infinity,
                                  height: 180,
                                  color: AppColors.textFieldBGColor,
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'Unable to load RTGS slip image',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _showRtgsImageSourceDialog,
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
                          Icons.receipt_long_outlined,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Upload RTGS slip',
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
                                color: AppColors.headingTextColor.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.upload, color: AppColors.primaryColor),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  void _showRtgsImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload RTGS Slip'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.camera_alt,
                color: AppColors.primaryColor,
              ),
              title: const Text('Camera'),
              subtitle: const Text('Capture image from camera'),
              onTap: () {
                Navigator.of(context).pop();
                Future.microtask(() => _pickRtgsImage(ImageSource.camera));
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: AppColors.primaryColor,
              ),
              title: const Text('Gallery'),
              subtitle: const Text('Select image from gallery'),
              onTap: () {
                Navigator.of(context).pop();
                Future.microtask(() => _pickRtgsImage(ImageSource.gallery));
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickRtgsImage(ImageSource source) async {
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
          rtgsImageName: pickedImage.name,
          rtgsImageBytes: imageBytes,
          existingRtgsImageUrl: null,
        );
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick RTGS slip image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
