import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/constant/app_colors.dart';
import '../../../config/constant/const_assets.dart';
import '../../../config/routes.dart';
import '../../../data/models/booking_summary_model.dart';
import '../../../data/repository/booking_api_repository.dart';
import '../../../data/models/request_models/booking_request_model.dart';
import '../../../data/models/request_models/hold_request_model.dart';
import '../../providers/projects_provider.dart';
import 'header_icon_widget.dart';
import 'action_buttons.dart';

class ReviewConfirmSection extends StatefulWidget {
  final String title;
  final String nextButtonText;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final BookingSummary bookingSummary;
  final bool isHoldFlow; // New parameter to distinguish between booking and hold flows
  final int agentId; // Agent ID for API calls
  final VoidCallback? onResetForm; // Callback to reset form data

  const ReviewConfirmSection({
    super.key,
    required this.title,
    required this.nextButtonText,
    this.onPrevious,
    required this.onNext,
    required this.bookingSummary,
    this.isHoldFlow = false,
    this.agentId = 1, // Default agent ID, should be passed from parent
    this.onResetForm, // Callback to reset form data
  });

  @override
  State<ReviewConfirmSection> createState() => _ReviewConfirmSectionState();
}

class _ReviewConfirmSectionState extends State<ReviewConfirmSection> {
  final BookingApiRepository _bookingRepository = BookingApiRepository();
  bool _isLoading = false;

  Future<void> _handleBookingAction() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.isHoldFlow) {
        await _createHold();
      } else {
        await _createBooking();
      }
      
      // Call project API after successful booking/hold creation
      await _callProjectApi();
      
      // Show success message and reset form
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isHoldFlow 
              ? 'Plot hold created successfully!' 
              : 'Booking created successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Reset form data and navigate to starting step
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            // Call the reset form callback if provided
            widget.onResetForm?.call();
            
            // Navigate to dashboard
            context.go(Routes.dashboardScreen);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        print("sdfds");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
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

  Future<void> _createBooking() async {
    final summary = widget.bookingSummary;
    
    if (summary.selectedPlot == null || 
        summary.selectedCustomer == null || 
        summary.paymentDetails == null || 
        summary.bankDetails == null) {
      throw Exception('Missing required data for booking');
    }

    final request = BookingRequestModel(
      plot: int.parse(summary.selectedPlot!.id),
      agent: widget.agentId,
      customer: summary.selectedCustomer!.id,
      customerName: summary.selectedCustomer!.name,
      customerPhone: summary.selectedCustomer!.phone,
      customerEmail: summary.selectedCustomer!.email ?? '',
      customerAddress: summary.selectedCustomer!.location ?? '',
      bookingType: summary.paymentDetails!.paymentTypeKey,
      bookingAmount: summary.paymentDetails!.paymentAmount,
      totalAmount: summary.paymentDetails!.paymentAmount, // Assuming same as booking amount
      paymentMode: summary.paymentDetails!.paymentMethodKey,
      paymentReference: _generatePaymentReference(),
      chequeNumber: summary.paymentDetails!.chequeNumber ?? '',
      chequeDate: summary.paymentDetails!.chequeDate?.toIso8601String().split('T')[0] ?? '',
      paymentDetails: _generatePaymentDetails(),
      panCard: summary.paymentDetails!.panNumber,
      aadharCard: summary.paymentDetails!.aadharNumber,
      accountHolderName: summary.bankDetails!.accountHolderName ?? '',
      branchName: summary.bankDetails!.branchName ?? '',
      accountNumber: summary.bankDetails!.accountNumber ?? '',
      ifscCode: summary.bankDetails!.ifscCode ?? '',
      accountType: summary.bankDetails!.accountType ?? '',
      bankContactNumber: summary.bankDetails!.contactNumber ?? '',
      status: 'completed',
      remarks: summary.paymentDetails!.additionalNotes,
      salaryIndividual: summary.paymentDetails!.isSalariedIndividual,
      salarySlipPath: summary.paymentDetails!.salarySlipPath,
      form16APath: summary.paymentDetails!.form16APath,
    );

    await _bookingRepository.createBooking(request);
  }

  Future<void> _createHold() async {
    final summary = widget.bookingSummary;
    
    if (summary.selectedPlot == null || 
        summary.selectedCustomer == null || 
        summary.holdDetails == null || 
        summary.bankDetails == null) {
      throw Exception('Missing required data for hold');
    }

    // Calculate hold until time (24 hours from now)
    final holdUntil = DateTime.now().add(const Duration(hours: 24));
    final holdUntilString = holdUntil.toIso8601String();

    final request = HoldRequestModel(
      plot: int.parse(summary.selectedPlot!.id),
      customer: summary.selectedCustomer!.id,
      agent: widget.agentId,
      customerName: summary.selectedCustomer!.name,
      customerPhone: summary.selectedCustomer!.phone,
      customerEmail: summary.selectedCustomer!.email ?? '',
      reraNumber: summary.holdDetails!.reraNumber,
      teamLeaderName: summary.holdDetails!.teamLeaderName ?? '',
      clientAadhar: summary.holdDetails!.clientAadhar,
      holdAmount: 0.0, // Default hold amount, should be configurable
      paymentMode: 'rtgs', // Default payment mode for holds
      paymentReference: _generatePaymentReference(),
      accountHolderName: summary.bankDetails!.accountHolderName ?? '',
      branchName: summary.bankDetails!.branchName ?? '',
      accountNumber: summary.bankDetails!.accountNumber ?? '',
      ifscCode: summary.bankDetails!.ifscCode ?? '',
      accountType: summary.bankDetails!.accountType ?? '',
      bankContactNumber: summary.bankDetails!.contactNumber ?? '',
      holdUntil: holdUntilString,
      remarks: summary.holdDetails!.additionalNotes ?? '',
    );

    await _bookingRepository.createHold(request);
  }

  String _generatePaymentReference() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'REF$timestamp';
  }

  String _generatePaymentDetails() {
    final summary = widget.bookingSummary;
    if (summary.paymentDetails == null) return '';
    
    final paymentMethod = summary.paymentDetails!.paymentMethod;
    final paymentType = summary.paymentDetails!.paymentType;
    
    return '$paymentMethod payment for $paymentType booking';
  }

  /// Call project API after successful booking/hold creation
  Future<void> _callProjectApi() async {
    try {
      print('Calling project API after successful ${widget.isHoldFlow ? 'hold' : 'booking'} creation...');
      
      // Refresh the projects provider state to update the project list
      // This will automatically update the BookingFormSection since it watches the provider
      if (mounted) {
        final container = ProviderScope.containerOf(context);
        await container.read(projectsControllerProvider.notifier).loadProjects();
        print('Projects provider refreshed after ${widget.isHoldFlow ? 'hold' : 'booking'} creation');
      }
    } catch (e) {
      print('Error refreshing projects provider after ${widget.isHoldFlow ? 'hold' : 'booking'} creation: $e');
      // Don't throw error here as the main booking/hold operation was successful
      // Just log the project API error
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 20, bottom: 20),
      child: Column(
        children: [
          // Header
          HeaderIconWidget(
            icon: IconsAssets.roundTickIcon,
            bgColor: AppColors.successColor.withAlpha((0.1 * 255).toInt()),
            iconColor: AppColors.successColor,
            title: widget.title,
            subtitle: 'Please review all details',
          ),
          
          const SizedBox(height: 40),
          
          // Customer Information Card
          _buildInfoCard(
            icon: IconsAssets.personIcon,
            iconColor: AppColors.primaryColor,
            title: 'Customer Information',
            children: [
              _buildInfoRow(
                'Name',
                widget.bookingSummary.selectedCustomer?.name ?? 'N/A',
              ),
              _buildInfoRow(
                'Phone',
                widget.bookingSummary.selectedCustomer?.phone ?? 'N/A',
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Plot Information Card
          _buildInfoCard(
            icon: IconsAssets.locationIcon,
            iconColor: Colors.red,
            title: 'Plot Information',
            children: [
              _buildInfoRow(
                'Plot',
                widget.bookingSummary.selectedPlot?.plotNumber ?? 'N/A',
              ),
              _buildInfoRow(
                'Project',
                widget.bookingSummary.selectedProject?.name ?? 'N/A',
              ),
              _buildInfoRow(
                'Area',
                '${widget.bookingSummary.selectedPlot?.area ?? 'N/A'} sq ft',
              ),
              _buildInfoRow(
                'Price',
                '₹${widget.bookingSummary.selectedPlot?.price ?? 'N/A'}',
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Payment Information Card
          if (!widget.isHoldFlow)
            _buildInfoCard(
              icon: IconsAssets.cardIcon,
              iconColor: AppColors.primaryColor,
              title: 'Payment Information',
              children: [
                _buildInfoRow(
                  'Amount',
                  '₹${widget.bookingSummary.paymentDetails?.paymentAmount ?? 'N/A'}',
                ),
                _buildInfoRow(
                  'Method',
                  widget.bookingSummary.paymentDetails?.paymentMethod ?? 'N/A',
                ),
                _buildInfoRow(
                  'Payment Type',
                  widget.bookingSummary.paymentDetails?.paymentType ?? 'N/A',
                ),
                _buildInfoRow(
                  'PAN',
                  _formatPAN(widget.bookingSummary.paymentDetails?.panNumber),
                ),
                _buildInfoRow(
                  'Aadhar',
                  _formatAadhar(widget.bookingSummary.paymentDetails?.aadharNumber),
                ),
              ],
            ),
          
          const SizedBox(height: 16),
          
          // Hold Details Card (only for hold flow)
          if (widget.isHoldFlow && widget.bookingSummary.holdDetails != null)
            _buildHoldDetailsCard(),
          
          if (widget.isHoldFlow && widget.bookingSummary.holdDetails != null)
            const SizedBox(height: 16),
          
          // Bank Details Card
          _buildInfoCard(
            icon: IconsAssets.bankIcon,
            iconColor: Colors.brown,
            title: 'Bank Details',
            children: [
              _buildInfoRow(
                'Account Holder Name',
                widget.bookingSummary.bankDetails?.accountHolderName ?? 'N/A',
              ),
              
              _buildInfoRow(
                'Branch Name',
                widget.bookingSummary.bankDetails?.branchName ?? 'N/A',
              ),
              _buildInfoRow(
                'Account Number',
                _formatAccountNumber(widget.bookingSummary.bankDetails?.accountNumber),
              ),
              _buildInfoRow(
                'IFSC Code',
                widget.bookingSummary.bankDetails?.ifscCode ?? 'N/A',
              ),
              _buildInfoRow(
                'Account Type',
                widget.bookingSummary.bankDetails?.accountType ?? 'N/A',
              ),
              _buildInfoRow(
                'Contact Number',
                widget.bookingSummary.bankDetails?.contactNumber ?? 'N/A',
              ),
            ],
          ),
          
          const SizedBox(height: 40),
          
          // Action buttons
          ActionButtons(
            onPrevious: widget.onPrevious,
            onNext: _isLoading ? null : _handleBookingAction,
            nextButtonText: _isLoading ? 'Processing...' : widget.nextButtonText,
            isPreviousEnabled: widget.onPrevious != null && !_isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String icon,
    Color? iconColor,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Image.asset(icon, color: iconColor ?? AppColors.primaryColor,)
              ),/*Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),*/
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.headingTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.darkGreyColor,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.headingTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPAN(String? pan) {
    if (pan == null || pan.isEmpty) return 'N/A';
    if (pan.length >= 10) {
      return '${pan.substring(0, 4)} ${pan.substring(4, 8)} ${pan.substring(8)}';
    }
    return pan;
  }

  String _formatAadhar(String? aadhar) {
    if (aadhar == null || aadhar.isEmpty) return 'N/A';
    if (aadhar.length >= 12) {
      return '${aadhar.substring(0, 4)} ${aadhar.substring(4, 8)} ${aadhar.substring(8)}';
    }
    return aadhar;
  }

  String _formatAccountNumber(String? accountNumber) {
    if (accountNumber == null || accountNumber.isEmpty) return 'N/A';
    if (accountNumber.length >= 16) {
      return '${accountNumber.substring(0, 4)} ${accountNumber.substring(4, 8)} ${accountNumber.substring(8, 12)} ${accountNumber.substring(12)}';
    }
    return accountNumber;
  }

  Widget _buildHoldDetailsCard() {
    final holdDetails = widget.bookingSummary.holdDetails!;
    return _buildInfoCard(
      icon: IconsAssets.holdTimeIcon,
      iconColor: Colors.orange,
      title: 'Hold Details',
      children: [
        _buildInfoRow(
          'RERA Number',
          holdDetails.reraNumber,
        ),
        _buildInfoRow(
          'Team Leader',
          holdDetails.teamLeaderName ?? 'N/A',
        ),
        _buildInfoRow(
          'Client Aadhar',
          _formatAadhar(holdDetails.clientAadhar),
        ),
        _buildInfoRow(
          'Additional Notes',
          holdDetails.additionalNotes ?? 'N/A',
        ),
      ],
    );
  }
}
