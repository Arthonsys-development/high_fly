import 'package:flutter/material.dart';
import 'package:highfly/data/models/hold_list_model.dart';
import 'package:highfly/data/models/hold_details_model.dart';
import 'package:highfly/data/models/bank_details_model.dart';
import 'package:highfly/data/repository/booking_api_repository.dart';
import '../../global/widgets/common_app_bar.dart';
import '../../widgets/booking/hold_details_section.dart';

class HoldEditScreen extends StatefulWidget {
  final HoldListModel hold;

  const HoldEditScreen({super.key, required this.hold});

  @override
  State<HoldEditScreen> createState() => _HoldEditScreenState();
}

class _HoldEditScreenState extends State<HoldEditScreen> {
  HoldDetails? _holdDetails;
  BankDetails? _bankDetails;
  bool _isLoading = false;
  final BookingApiRepository _bookingRepository = BookingApiRepository();

  @override
  void initState() {
    super.initState();
    // Initialize with existing hold data
    _holdDetails = HoldDetails(
      associateNameOrSelf: '',
      reraNumber: widget.hold.reraNumber,
      teamLeaderName: widget.hold.teamLeaderName.isNotEmpty ? widget.hold.teamLeaderName : null,
      clientAadhar: widget.hold.clientAadhar,
      additionalNotes: widget.hold.remarks.isNotEmpty ? widget.hold.remarks : null,
    );
    
    _bankDetails = BankDetails(
      accountHolderName: widget.hold.accountHolderName.isNotEmpty ? widget.hold.accountHolderName : null,
      branchName: widget.hold.branchName.isNotEmpty ? widget.hold.branchName : null,
      accountNumber: widget.hold.accountNumber.isNotEmpty ? widget.hold.accountNumber : null,
      ifscCode: widget.hold.ifscCode.isNotEmpty ? widget.hold.ifscCode : null,
      accountType: widget.hold.accountType.isNotEmpty ? widget.hold.accountType.toLowerCase() : null,
      contactNumber: widget.hold.bankContactNumber.isNotEmpty ? widget.hold.bankContactNumber : null,
    );
  }

  Future<void> _submitUpdate() async {
    if (_holdDetails == null) {
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
        'customer': widget.hold.customer,
        
        // Hold Details Section fields
        'associate_name_or_self': _holdDetails!.associateNameOrSelf.isNotEmpty ? _holdDetails!.associateNameOrSelf : '',
        'rera_number': _holdDetails!.reraNumber.isNotEmpty ? _holdDetails!.reraNumber : '',
        'client_aadhar': _holdDetails!.clientAadhar.isNotEmpty ? _holdDetails!.clientAadhar : '',
        'team_leader_name': _holdDetails!.teamLeaderName?.isNotEmpty == true ? _holdDetails!.teamLeaderName : '',
        'remarks': _holdDetails!.additionalNotes?.isNotEmpty == true ? _holdDetails!.additionalNotes : '',
        
        // Bank Details Section fields
        'account_holder_name': _bankDetails!.accountHolderName?.isNotEmpty == true ? _bankDetails!.accountHolderName : '',
        'branch_name': _bankDetails!.branchName?.isNotEmpty == true ? _bankDetails!.branchName : '',
        'account_number': _bankDetails!.accountNumber?.isNotEmpty == true ? _bankDetails!.accountNumber : '',
        'ifsc_code': _bankDetails!.ifscCode?.isNotEmpty == true ? _bankDetails!.ifscCode : '',
        'account_type': _bankDetails!.accountType?.isNotEmpty == true ? _bankDetails!.accountType : '',
        'bank_contact_number': _bankDetails!.contactNumber?.isNotEmpty == true ? _bankDetails!.contactNumber : '',
      };

      await _bookingRepository.updateHold(widget.hold.id, updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hold updated successfully!'),
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
        child: commonAppBar(context, "Edit Hold"),
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
    final saleableSizeVal = widget.hold.saleableSize != null
        ? double.tryParse(widget.hold.saleableSize!)
        : null;

    return HoldDetailsSection(
      title: "Hold Details",
      nextButtonText: "Submit",
      initialHoldDetails: _holdDetails,
      saleableSize: saleableSizeVal,
      onNext: (holdDetails) {
        setState(() {
          _holdDetails = holdDetails;
        });
        _submitUpdate();
      },
    );
  }
}

