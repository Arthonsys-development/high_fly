import 'package:flutter/material.dart';
import 'package:highfly/data/models/booking_list_model.dart';
import 'package:highfly/data/models/payment_model.dart';
import 'package:highfly/data/models/bank_details_model.dart';
import 'package:highfly/data/repository/booking_api_repository.dart';
import '../../global/widgets/common_app_bar.dart';
import '../../widgets/booking/payment_details_section.dart';
import '../../widgets/booking/bank_details_section.dart';

class BookingEditScreen extends StatefulWidget {
  final BookingListModel booking;

  const BookingEditScreen({super.key, required this.booking});

  @override
  State<BookingEditScreen> createState() => _BookingEditScreenState();
}

class _BookingEditScreenState extends State<BookingEditScreen> {
  int _currentStep = 0; // 0: Payment Details, 1: Bank Details
  PaymentDetails? _paymentDetails;
  BankDetails? _bankDetails;
  bool _isLoading = false;
  final BookingApiRepository _bookingRepository = BookingApiRepository();

  /// Parse cheque date from various formats (YYYY-MM-DD, DD/MM/YYYY, DD-MM-YYYY)
  DateTime? _parseChequeDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    
    // Try ISO 8601 format first (YYYY-MM-DD)
    DateTime? parsedDate = DateTime.tryParse(dateString);
    if (parsedDate != null) return parsedDate;
    
    // Try DD/MM/YYYY or DD-MM-YYYY format
    final parts = dateString.split(RegExp(r'[/-]'));
    if (parts.length == 3) {
      try {
        final day = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);
        
        if (day != null && month != null && year != null) {
          // Check if it's DD/MM/YYYY format (day <= 31, month <= 12)
          if (day <= 31 && month <= 12) {
            return DateTime(year, month, day);
          }
        }
      } catch (e) {
        // Failed to parse
      }
    }
    
    return null;
  }

  @override
  void initState() {
    super.initState();
    // Initialize with existing booking data
    final paymentModeKey = widget.booking.paymentMode.toLowerCase();
    final bookingTypeKey = widget.booking.bookingType.toLowerCase();
    final paymentMethodLabel = PaymentMethod.getValue(paymentModeKey).isNotEmpty
        ? PaymentMethod.getValue(paymentModeKey)
        : widget.booking.paymentMode;
    final bookingTypeLabel = PaymentType.getValue(bookingTypeKey).isNotEmpty
        ? PaymentType.getValue(bookingTypeKey)
        : widget.booking.bookingType;

    _paymentDetails = PaymentDetails(
      paymentAmount: widget.booking.bookingAmount,
      paymentMethod: paymentMethodLabel,
      paymentMethodKey: paymentModeKey,
      paymentType: bookingTypeLabel,
      paymentTypeKey: bookingTypeKey,
      panNumber: widget.booking.panCard.isNotEmpty ? widget.booking.panCard : '',
      aadharNumber: widget.booking.aadharCard.isNotEmpty ? widget.booking.aadharCard : '',
      isSalariedIndividual: widget.booking.salaryIndividual,
      salarySlipPath: widget.booking.salarySlip,
      form16APath: widget.booking.form16a,
      additionalNotes: widget.booking.remarks.isNotEmpty ? widget.booking.remarks : '',
      chequeNumber: widget.booking.chequeNumber.isNotEmpty ? widget.booking.chequeNumber : null,
      chequeDate: _parseChequeDate(widget.booking.chequeDate),
    );
    
    _bankDetails = BankDetails(
      accountHolderName: widget.booking.accountHolderName.isNotEmpty ? widget.booking.accountHolderName : null,
      branchName: widget.booking.branchName.isNotEmpty ? widget.booking.branchName : null,
      accountNumber: widget.booking.accountNumber.isNotEmpty ? widget.booking.accountNumber : null,
      ifscCode: widget.booking.ifscCode.isNotEmpty ? widget.booking.ifscCode : null,
      accountType: widget.booking.accountType.isNotEmpty ? widget.booking.accountType.toLowerCase() : null,
      contactNumber: widget.booking.bankContactNumber.isNotEmpty ? widget.booking.bankContactNumber : null,
    );
  }

  Future<void> _submitUpdate() async {
    if (_paymentDetails == null || _bankDetails == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare update data with all fields from both sections
      final updateData = <String, dynamic>{
        // Customer ID (required)
        'customer': widget.booking.customer,
        
        // Payment Details Section fields
        'booking_amount': _paymentDetails!.paymentAmount.isNotEmpty ? _paymentDetails!.paymentAmount : '',
        'total_amount': _paymentDetails!.paymentAmount.isNotEmpty ? _paymentDetails!.paymentAmount : '',
        'payment_mode': _paymentDetails!.paymentMethodKey.isNotEmpty ? _paymentDetails!.paymentMethodKey : '',
        'payment_reference': widget.booking.paymentReference.isNotEmpty ? widget.booking.paymentReference : '',
        'booking_type': _paymentDetails!.paymentTypeKey.isNotEmpty ? _paymentDetails!.paymentTypeKey : '',
        'pan_card': _paymentDetails!.panNumber.isNotEmpty ? _paymentDetails!.panNumber : '',
        'aadhar_card': _paymentDetails!.aadharNumber.isNotEmpty ? _paymentDetails!.aadharNumber : '',
        'salary_individual': _paymentDetails!.isSalariedIndividual,
        'remarks': _paymentDetails!.additionalNotes.isNotEmpty ? _paymentDetails!.additionalNotes : '',
        'cheque_number': _paymentDetails!.chequeNumber?.isNotEmpty == true ? _paymentDetails!.chequeNumber : '',
        'cheque_date': _paymentDetails!.chequeDate != null
            ? _paymentDetails!.chequeDate!.toIso8601String().split('T')[0]
            : '',
        
        // File paths (will be converted to MultipartFile in repository)
        if (_paymentDetails!.salarySlipPath != null && _paymentDetails!.salarySlipPath!.isNotEmpty)
          'salary_slip_path': _paymentDetails!.salarySlipPath!,
        if (_paymentDetails!.form16APath != null && _paymentDetails!.form16APath!.isNotEmpty)
          'form_16a_path': _paymentDetails!.form16APath!,
        
        // Bank Details Section fields
        'account_holder_name': _bankDetails!.accountHolderName?.isNotEmpty == true ? _bankDetails!.accountHolderName : '',
        'branch_name': _bankDetails!.branchName?.isNotEmpty == true ? _bankDetails!.branchName : '',
        'account_number': _bankDetails!.accountNumber?.isNotEmpty == true ? _bankDetails!.accountNumber : '',
        'ifsc_code': _bankDetails!.ifscCode?.isNotEmpty == true ? _bankDetails!.ifscCode : '',
        'account_type': _bankDetails!.accountType?.isNotEmpty == true ? _bankDetails!.accountType : '',
        'bank_contact_number': _bankDetails!.contactNumber?.isNotEmpty == true ? _bankDetails!.contactNumber : '',
      };

      await _bookingRepository.updateBooking(widget.booking.id, updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking updated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate back with success flag
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.of(context).pop(true); // Return true to indicate successful update
          }
        });
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(11);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: commonAppBar(context, "Edit Booking"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildCurrentStep(),
            ),
    );
  }

  Widget _buildCurrentStep() {
    if (_currentStep == 0) {
      // Payment Details Section
      return PaymentDetailsSection(
        title: "Payment Details",
        paymentAmount: widget.booking.bookingAmount,
        nextButtonText: "Next",
        initialPaymentDetails: _paymentDetails,
        onNext: (paymentDetails) {
          setState(() {
            _paymentDetails = paymentDetails;
            _currentStep = 1; // Move to bank details
          });
        },
      );
    } else {
      // Bank Details Section
      return BankDetailsSection(
        title: "Bank Details",
        nextButtonText: "Submit",
        initialBankDetails: _bankDetails,
        onPrevious: () {
          setState(() {
            _currentStep = 0; // Go back to payment details
          });
        },
        onNext: (bankDetails) {
          setState(() {
            _bankDetails = bankDetails;
          });
          _submitUpdate();
        },
      );
    }
  }
}

