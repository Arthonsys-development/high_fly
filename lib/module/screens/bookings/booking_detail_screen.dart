import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:highfly/config/constant/app_colors.dart';
import 'package:highfly/data/models/booking_list_model.dart';
import 'package:highfly/data/models/payment_model.dart';
import '../../providers/bookings_provider.dart';
import 'webview_screen.dart';
import 'booking_edit_screen.dart';

String _formatStatusDisplay(String statusDisplay) {
  if (statusDisplay.isEmpty) return statusDisplay;
  
  // If it contains "/", capitalize each part separately
  if (statusDisplay.contains('/')) {
    return statusDisplay.split('/').map((part) {
      return part.trim().isEmpty 
          ? part 
          : part.trim()[0].toUpperCase() + part.trim().substring(1).toLowerCase();
    }).join('/');
  }
  
  // Capitalize first letter, rest lowercase
  return statusDisplay[0].toUpperCase() + statusDisplay.substring(1).toLowerCase();
}

class BookingDetailScreen extends ConsumerStatefulWidget {
  final BookingListModel booking;

  const BookingDetailScreen({super.key, required this.booking});

  @override
  ConsumerState<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends ConsumerState<BookingDetailScreen> {
  late BookingListModel _currentBooking;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentBooking = widget.booking;
  }

  bool _isBookingCancelled() {
    final status = _currentBooking.status.toLowerCase();
    return (status == 'cancelled' || status == 'canceled') ||
           (_currentBooking.cancelledAt != null && _currentBooking.cancelledAt!.isNotEmpty);
  }

  Future<void> _refreshBookingData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Refresh bookings list from provider
      await ref.read(bookingsControllerProvider.notifier).loadBookings();
      
      // Find the updated booking in the list
      final bookings = ref.read(bookingsControllerProvider).bookings;
      final updatedBooking = bookings.firstWhere(
        (b) => b.id == _currentBooking.id,
        orElse: () => _currentBooking,
      );

      if (mounted) {
        setState(() {
          _currentBooking = updatedBooking;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _navigateToEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingEditScreen(booking: _currentBooking),
      ),
    );

    // If update was successful, refresh the data
    if (result == true && mounted) {
      await _refreshBookingData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = _currentBooking;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          title: const Text("Booking Details"),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.primaryTextColor),
            onPressed: () => Navigator.of(context).pop(),
          ),
          backgroundColor: Colors.white,
          titleTextStyle: TextStyle(color: AppColors.primaryTextColor, fontSize: 18, fontWeight: FontWeight.bold),
          iconTheme: IconThemeData(color: AppColors.primaryTextColor),
          centerTitle: true,
          elevation: 1,
          actions: [
            if (!_isBookingCancelled())
              IconButton(
                icon: const Icon(Icons.edit, color: AppColors.primaryColor),
                onPressed: _isLoading ? null : _navigateToEdit,
                tooltip: 'Edit Booking',
              )
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(kIsWeb ? 32.0 : 16.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: kIsWeb ? 1200 : double.infinity,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  // Status Card
                  Builder(
                    builder: (context) {
                      Color statusColor;
                      IconData statusIcon;
                      
                      final status = booking.status.toLowerCase();
                if (status == 'cancelled' || status == 'canceled') {
                  statusColor = Colors.red;
                  statusIcon = Icons.cancel_outlined;
                } else if (status == 'completed' || status == 'sold') {
                  statusColor = Colors.green;
                  statusIcon = Icons.check_circle_outline;
                } else if (status == 'pending' || status == 'processing') {
                  statusColor = Colors.orange;
                  statusIcon = Icons.pending_outlined;
                } else {
                  statusColor = Colors.blue;
                  statusIcon = Icons.info_outline;
                }
                
                return Container(
                  padding: EdgeInsets.all(kIsWeb ? 20 : 16),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(kIsWeb ? 16 : 12),
                    border: Border.all(
                      color: statusColor,
                      width: kIsWeb ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status',
                            style: TextStyle(
                              fontSize: kIsWeb ? 15 : 14,
                              color: AppColors.lightGreyColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: kIsWeb ? 6 : 4),
                          Text(
                            _formatStatusDisplay(booking.statusDisplay),
                            style: TextStyle(
                              fontSize: kIsWeb ? 20 : 18,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                              letterSpacing: kIsWeb ? 0.3 : 0,
                            ),
                          ),
                        ],
                      ),
                      Icon(statusIcon, color: statusColor, size: kIsWeb ? 36 : 32),
                    ],
                  ),
                );
              },
            ),
            SizedBox(height: kIsWeb ? 32 : 24),

            // Plot Information Section
            _buildSectionTitle('Plot Information'),
            _buildDetailCard([
              _buildDetailRow('Plot No.', booking.plotCode),
              if (booking.project != null)
                _buildDetailRow('Project', booking.project!.name),
              if (booking.plotSize != null && booking.plotSize!.isNotEmpty)
                _buildDetailRow('Plot Size', booking.plotSize!),
              if (booking.plotArea != null && booking.plotArea!.isNotEmpty)
                _buildDetailRow('Plot Area', '${booking.plotArea} sq ft'),
              if (booking.plotPrice != null && booking.plotPrice!.isNotEmpty)
                _buildDetailRow('Plot Price', '₹${booking.plotPrice}'),
              if (booking.plotFacing != null && booking.plotFacing!.isNotEmpty)
                _buildDetailRow('Plot Facing', booking.plotFacing!),
              _buildDetailRow('Booking Type', PaymentType.getValue(booking.bookingType.toLowerCase()).isNotEmpty 
                  ? PaymentType.getValue(booking.bookingType.toLowerCase()) 
                  : booking.bookingType),
              _buildDetailRow('Booking Amount', '₹${booking.bookingAmount}'),
              _buildDetailRow('Total Amount', '₹${booking.totalAmount}'),
             // _buildDetailRow('Booking Date', booking.bookingDate),
              _buildDetailRow('Booked At', booking.bookedAt),
            ]),
            SizedBox(height: kIsWeb ? 32 : 24),

            // Customer Information and Payment Information in a row for web
            if (kIsWeb)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Customer Information'),
                        _buildDetailCard([
                          _buildDetailRow('Customer Name', booking.customerName),
                          _buildDetailRow('Phone', booking.customerPhone),
                          if (booking.customerEmail.isNotEmpty)
                            _buildDetailRow('Email', booking.customerEmail),
                          if (booking.customerAddress.isNotEmpty)
                            _buildDetailRow('Address', booking.customerAddress),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Payment Information'),
                        _buildDetailCard([
                          _buildDetailRow('Payment Mode', PaymentMethod.getValue(booking.paymentMode).isNotEmpty 
                              ? PaymentMethod.getValue(booking.paymentMode) 
                              : booking.paymentMode),
                          _buildDetailRow('Payment Reference', booking.paymentReference),
                          if (booking.chequeNumber.isNotEmpty)
                            _buildDetailRow('Cheque Number', booking.chequeNumber),
                          if (booking.chequeDate != null && booking.chequeDate!.isNotEmpty)
                            _buildDetailRow('Cheque Date', booking.chequeDate!),
                          if (booking.paymentDetails.isNotEmpty)
                            _buildDetailRow('Payment Details', booking.paymentDetails),
                        ]),
                      ],
                    ),
                  ),
                ],
              )
            else ...[
              // Customer Information Section
              _buildSectionTitle('Customer Information'),
              _buildDetailCard([
                _buildDetailRow('Customer Name', booking.customerName),
                _buildDetailRow('Phone', booking.customerPhone),
                if (booking.customerEmail.isNotEmpty)
                  _buildDetailRow('Email', booking.customerEmail),
                if (booking.customerAddress.isNotEmpty)
                  _buildDetailRow('Address', booking.customerAddress),
              ]),
              const SizedBox(height: 24),

              // Payment Information Section
              _buildSectionTitle('Payment Information'),
              _buildDetailCard([
                _buildDetailRow('Payment Mode', PaymentMethod.getValue(booking.paymentMode).isNotEmpty 
                    ? PaymentMethod.getValue(booking.paymentMode) 
                    : booking.paymentMode),
                /*_buildDetailRow('Payment Reference', booking.paymentReference),*/
                if (booking.chequeNumber.isNotEmpty)
                  _buildDetailRow('Cheque Number', booking.chequeNumber),
                if (booking.chequeDate != null && booking.chequeDate!.isNotEmpty)
                  _buildDetailRow('Cheque Date', booking.chequeDate!),
                if (booking.paymentDetails.isNotEmpty)
                  _buildDetailRow('Payment Details', booking.paymentDetails),
              ]),
            ],
            SizedBox(height: kIsWeb ? 32 : 24),

            // Document Information Section
            _buildSectionTitle('Document Information'),
            _buildDetailCard([
              _buildDetailRow('PAN Card', booking.panCard),
              _buildDetailRow('Aadhar Card', booking.aadharCard),
              if (booking.salaryIndividual && booking.salarySlip != null && booking.salarySlip!.isNotEmpty)
                _buildDocumentRow(context, 'Salary Slip', booking.salarySlip!),
              if (booking.salaryIndividual && booking.form16a != null && booking.form16a!.isNotEmpty)
                _buildDocumentRow(context, 'Form 16A', booking.form16a!),
              if (booking.bankStatement != null && booking.bankStatement!.isNotEmpty)
                _buildDocumentRow(context, 'Bank Statement', booking.bankStatement!),
              if (booking.otherDocuments != null && booking.otherDocuments!.isNotEmpty)
                _buildDocumentRow(context, 'Other Documents', booking.otherDocuments!),
            ]),
            SizedBox(height: kIsWeb ? 32 : 24),

            // Bank Details Section
            _buildSectionTitle('Bank Details'),
            _buildDetailCard([
              _buildDetailRow('Account Holder Name', booking.accountHolderName),
              _buildDetailRow('Branch Name', booking.branchName),
              _buildDetailRow('Account Number', booking.accountNumber),
              _buildDetailRow('IFSC Code', booking.ifscCode),
              _buildDetailRow('Account Type', booking.accountType),
              _buildDetailRow('Bank Contact', booking.bankContactNumber),
            ]),
            SizedBox(height: kIsWeb ? 32 : 24),

            // Remarks Section
            if (booking.remarks.isNotEmpty) ...[
              _buildSectionTitle('Remarks'),
              _buildDetailCard([
                _buildDetailRow('Notes', booking.remarks),
              ]),
              SizedBox(height: kIsWeb ? 32 : 24),
            ],

            // Cancellation Information (if cancelled)
            if (booking.cancelledAt != null && booking.cancelledAt!.isNotEmpty) ...[
              _buildSectionTitle('Cancellation Information'),
              _buildDetailCard([
                _buildDetailRow('Cancelled At', booking.cancelledAt!),
                if (booking.cancelledBy != null && booking.cancelledBy!.isNotEmpty)
                  _buildDetailRow('Cancelled By', booking.cancelledBy!),
                if (booking.cancellationReason != null && booking.cancellationReason!.isNotEmpty)
                  _buildDetailRow('Cancellation Reason', booking.cancellationReason!),
              ]),
              SizedBox(height: kIsWeb ? 32 : 24),
            ],

            // Additional Information
            // _buildSectionTitle('Additional Information'),
            // _buildDetailCard([
            //   _buildDetailRow('Agent Name', booking.agentName),
            //   _buildDetailRow('Created At', booking.createdAt),
            //   _buildDetailRow('Updated At', booking.updatedAt),
            //   if (booking.fromHold != null && booking.fromHold!.isNotEmpty)
            //     _buildDetailRow('From Hold', booking.fromHold!),
            // ]),
            // const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: kIsWeb ? 16.0 : 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: kIsWeb ? 22 : 20,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryTextColor,
          letterSpacing: kIsWeb ? 0.5 : 0,
        ),
      ),
    );
  }

  Widget _buildDetailCard(List<Widget> children) {
    return Container(
      padding: EdgeInsets.all(kIsWeb ? 24 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kIsWeb ? 16 : 12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: kIsWeb ? 0.08 : 0.1),
            spreadRadius: kIsWeb ? 0 : 1,
            blurRadius: kIsWeb ? 8 : 4,
            offset: Offset(0, kIsWeb ? 4 : 2),
          ),
        ],
        border: kIsWeb ? Border.all(
          color: Colors.grey.withValues(alpha: 0.1),
          width: 1,
        ) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isLink = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: kIsWeb ? 16.0 : 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: kIsWeb ? 180 : 140,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: kIsWeb ? 15 : 14,
                color: AppColors.lightGreyColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: isLink && value.isNotEmpty
                ? InkWell(
                    onTap: () {
                      // Open link in browser
                    },
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: kIsWeb ? 15 : 14,
                        color: Colors.blue,
                        fontWeight: FontWeight.w400,
                        decoration: TextDecoration.underline,
                        height: kIsWeb ? 1.5 : 1.4,
                      ),
                    ),
                  )
                : Text(
                    value.isNotEmpty ? value : '-',
                    style: TextStyle(
                      fontSize: kIsWeb ? 15 : 14,
                      color: AppColors.primaryTextColor,
                      fontWeight: FontWeight.w400,
                      height: kIsWeb ? 1.5 : 1.4,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentRow(BuildContext context, String label, String url) {
    // Extract filename from URL
    String fileName = url.split('/').last;
    if (fileName.contains('?')) {
      fileName = fileName.split('?').first;
    }
    
    return Padding(
      padding: EdgeInsets.only(bottom: kIsWeb ? 16.0 : 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: kIsWeb ? 180 : 140,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: kIsWeb ? 15 : 14,
                color: AppColors.lightGreyColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    fileName,
                    style: TextStyle(
                      fontSize: kIsWeb ? 15 : 14,
                      color: AppColors.primaryTextColor,
                      fontWeight: FontWeight.w400,
                      height: kIsWeb ? 1.5 : 1.4,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: kIsWeb ? 12 : 8),
                SizedBox(
                  width: kIsWeb ? 36 : 32,
                  height: kIsWeb ? 36 : 32,
                  child: IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WebViewScreen(
                            url: url,
                            title: label,
                          ),
                        ),
                      );
                    },
                    icon: Icon(Icons.visibility, size: kIsWeb ? 22 : 20),
                    color: AppColors.primaryColor,
                    tooltip: 'View',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

