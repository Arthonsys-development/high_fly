import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../config/constant/app_strings.dart';
import '../../../data/models/hold_list_model.dart';
import '../../../data/models/payment_model.dart';
import '../../../data/models/request_models/booking_request_model.dart';
import '../../../data/repository/booking_api_repository.dart';
import '../../global/widgets/common_app_bar.dart';
import '../../widgets/booking/payment_details_section.dart';

class HoldBookingScreen extends StatefulWidget {
  final HoldListModel hold;

  const HoldBookingScreen({super.key, required this.hold});

  @override
  State<HoldBookingScreen> createState() => _HoldBookingScreenState();
}

class _HoldBookingScreenState extends State<HoldBookingScreen> {
  PaymentDetails? _paymentDetails;
  bool _isLoading = false;
  final BookingApiRepository _bookingRepository = BookingApiRepository();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  String _generatePaymentReference() {
    if (_paymentDetails?.paymentMethodKey == 'upi' &&
        (_paymentDetails?.upiTransactionId ?? '').isNotEmpty) {
      return _paymentDetails!.upiTransactionId!;
    }
    return '';
  }

  String _generatePaymentDetails() {
    if (_paymentDetails == null) return '';
    
    final paymentMethod = _paymentDetails!.paymentMethod;
    final paymentType = _paymentDetails!.paymentType;
    
    return '$paymentMethod payment for $paymentType booking';
  }

  Future<void> _submitBooking() async {
    if (_paymentDetails == null) {
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
      final agentId = await _secureStorage.read(key: SharedPreferenceStrings.id) ?? '';
      
      if (agentId.isEmpty) {
        throw Exception('Agent ID not found');
      }

      // Use bank details from the hold
      final request = BookingRequestModel(
        plotIds: widget.hold.allPlotIds,
        agent: int.parse(agentId),
        customer: widget.hold.customer,
        customerName: widget.hold.customerName,
        customerPhone: widget.hold.customerPhone,
        customerEmail: widget.hold.customerEmail,
        customerAddress: '', // Not available in hold
        bookingType: _paymentDetails!.paymentTypeKey,
        bookingAmount: _paymentDetails!.paymentAmount,
        totalAmount: _paymentDetails!.totalAmount.isNotEmpty
            ? _paymentDetails!.totalAmount
            : _paymentDetails!.paymentAmount,
        pricePerSqYd: _paymentDetails!.pricePerSqYd.isNotEmpty
            ? _paymentDetails!.pricePerSqYd
            : null,
        paymentMode: _paymentDetails!.paymentMethodKey,
        paymentReference: _generatePaymentReference(),
        chequeNumber: _paymentDetails!.chequeNumber ?? '',
        chequeDate: _paymentDetails!.chequeDate?.toIso8601String().split('T')[0] ?? '',
        paymentDetails: _generatePaymentDetails(),
        panCard: _paymentDetails!.panNumber,
        aadharCard: _paymentDetails!.aadharNumber,
        accountHolderName: widget.hold.accountHolderName,
        branchName: widget.hold.branchName,
        accountNumber: widget.hold.accountNumber,
        ifscCode: widget.hold.ifscCode,
        accountType: widget.hold.accountType,
        bankContactNumber: widget.hold.bankContactNumber,
        status: 'completed',
        remarks: _paymentDetails!.additionalNotes,
        salaryIndividual: _paymentDetails!.isSalariedIndividual,
        salarySlipPath: _paymentDetails!.salarySlipPath,
        form16APath: _paymentDetails!.form16APath,
        chequeImageName: _paymentDetails!.chequeImageName,
        chequeImageBytes: _paymentDetails!.chequeImageBytes,
        rtgsImageName: _paymentDetails!.rtgsImageName,
        rtgsImageBytes: _paymentDetails!.rtgsImageBytes,
        holdId: widget.hold.id,
        loanBankName: _paymentDetails!.loanBankName,
        loanBankKey: _paymentDetails!.loanBankKey,
        loanAmount: _paymentDetails!.loanAmount,
      );

      await _bookingRepository.createBooking(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking created successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate back to hold detail screen after success
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            // Pop the booking screen and return true to indicate success
            Navigator.of(context).pop(true);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        // Extract error message, removing "Exception: " prefix if present
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
        child: commonAppBar(context, "Book Now"),
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
    final saleableSizeVal = widget.hold.combinedSaleableSizeSqYd;

    // Only Payment Details Step - bank details are already in the hold
    return PaymentDetailsSection(
      title: "Payment Details",
      paymentAmount: widget.hold.aggregatedPlotPrice ?? widget.hold.holdAmount,
      nextButtonText: "Submit",
      initialPaymentDetails: _paymentDetails,
      saleableSize: saleableSizeVal,
      plcApplied: widget.hold.plcApplied,
      plcPercentage: widget.hold.plcPercentage,
      expectedPayName: widget.hold.project?.payName,
      onNext: (paymentDetails) {
        setState(() {
          _paymentDetails = paymentDetails;
        });
        _submitBooking();
      },
    );
  }
}

