import 'package:flutter/material.dart';
import 'package:highfly/config/constant/app_colors.dart';
import 'package:highfly/data/models/booking_list_model.dart';
import '../../global/widgets/common_app_bar.dart';
import 'webview_screen.dart';

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

class BookingDetailScreen extends StatelessWidget {
  final BookingListModel booking;

  const BookingDetailScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: commonAppBar(context, "Booking Details"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: statusColor,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Status',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.lightGreyColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatStatusDisplay(booking.statusDisplay),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                      Icon(statusIcon, color: statusColor, size: 32),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

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
              _buildDetailRow('Booking Type', booking.bookingType),
              _buildDetailRow('Booking Amount', '₹${booking.bookingAmount}'),
              _buildDetailRow('Total Amount', '₹${booking.totalAmount}'),
             // _buildDetailRow('Booking Date', booking.bookingDate),
              _buildDetailRow('Booked At', booking.bookedAt),
            ]),
            const SizedBox(height: 24),

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
              _buildDetailRow('Payment Mode', booking.paymentMode),
              _buildDetailRow('Payment Reference', booking.paymentReference),
              if (booking.chequeNumber.isNotEmpty)
                _buildDetailRow('Cheque Number', booking.chequeNumber),
              if (booking.chequeDate != null && booking.chequeDate!.isNotEmpty)
                _buildDetailRow('Cheque Date', booking.chequeDate!),
              if (booking.paymentDetails.isNotEmpty)
                _buildDetailRow('Payment Details', booking.paymentDetails),
            ]),
            const SizedBox(height: 24),

            // Document Information Section
            _buildSectionTitle('Document Information'),
            _buildDetailCard([
              _buildDetailRow('PAN Card', booking.panCard),
              _buildDetailRow('Aadhar Card', booking.aadharCard),
              if (booking.salarySlip != null && booking.salarySlip!.isNotEmpty)
                _buildDocumentRow(context, 'Salary Slip', booking.salarySlip!),
              if (booking.form16a != null && booking.form16a!.isNotEmpty)
                _buildDocumentRow(context, 'Form 16A', booking.form16a!),
              if (booking.bankStatement != null && booking.bankStatement!.isNotEmpty)
                _buildDocumentRow(context, 'Bank Statement', booking.bankStatement!),
              if (booking.otherDocuments != null && booking.otherDocuments!.isNotEmpty)
                _buildDocumentRow(context, 'Other Documents', booking.otherDocuments!),
            ]),
            const SizedBox(height: 24),

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
            const SizedBox(height: 24),

            // Remarks Section
            if (booking.remarks.isNotEmpty) ...[
              _buildSectionTitle('Remarks'),
              _buildDetailCard([
                _buildDetailRow('Notes', booking.remarks),
              ]),
              const SizedBox(height: 24),
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
              const SizedBox(height: 24),
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
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryTextColor,
        ),
      ),
    );
  }

  Widget _buildDetailCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isLink = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
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
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                        fontWeight: FontWeight.w400,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                : Text(
                    value.isNotEmpty ? value : '-',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.primaryTextColor,
                      fontWeight: FontWeight.w400,
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
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
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
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.primaryTextColor,
                      fontWeight: FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 32,
                  height: 32,
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
                    icon: const Icon(Icons.visibility, size: 20),
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

