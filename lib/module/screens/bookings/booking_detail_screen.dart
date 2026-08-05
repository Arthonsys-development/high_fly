import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:highfly/config/constant/app_colors.dart';
import 'package:highfly/data/models/booking_list_model.dart';
import 'package:highfly/data/models/booking_document_model.dart'
    as booking_document_model;
import 'package:highfly/data/models/payment_model.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/bookings_provider.dart';
import '../../utils/responsive.dart';
import 'webview_screen.dart';
import 'booking_edit_screen.dart';
import 'booking_document_management_screen.dart';
import '../../widgets/booking/plot_details_card.dart';
// Conditional import for web image widget
import '../visitors/web_image_widget.dart'
    if (dart.library.io) '../visitors/web_image_widget_stub.dart';

String _formatStatusDisplay(String statusDisplay) {
  if (statusDisplay.isEmpty) return statusDisplay;

  // If it contains "/", capitalize each part separately
  if (statusDisplay.contains('/')) {
    return statusDisplay
        .split('/')
        .map((part) {
          return part.trim().isEmpty
              ? part
              : part.trim()[0].toUpperCase() +
                    part.trim().substring(1).toLowerCase();
        })
        .join('/');
  }

  // Capitalize first letter, rest lowercase
  return statusDisplay[0].toUpperCase() +
      statusDisplay.substring(1).toLowerCase();
}

class BookingDetailScreen extends ConsumerStatefulWidget {
  final BookingListModel booking;

  const BookingDetailScreen({super.key, required this.booking});

  @override
  ConsumerState<BookingDetailScreen> createState() =>
      _BookingDetailScreenState();
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
        (_currentBooking.cancelledAt != null &&
            _currentBooking.cancelledAt!.isNotEmpty);
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

  // Returns true for desktop web UI, false for mobile UI (mobile browser or native app)
  bool _isDesktopWeb(BuildContext context) {
    return !Responsive.isMobile(context) && kIsWeb;
  }

  @override
  Widget build(BuildContext context) {
    final booking = _currentBooking;
    final isDesktopWeb = _isDesktopWeb(context);
    final bookingTypeKey = booking.bookingType.toLowerCase();
    final bookingTypeDisplay = PaymentType.getValue(bookingTypeKey).isNotEmpty
        ? PaymentType.getValue(bookingTypeKey)
        : booking.bookingType;
    final isWithoutLoan =
        bookingTypeKey == PaymentType.oneTime ||
        bookingTypeDisplay.toLowerCase() ==
            PaymentType.all[PaymentType.oneTime]!.toLowerCase();

    final String? totalAmountDisplay = () {
      if (booking.plotDetails.isNotEmpty) {
        double sum = 0;
        for (final p in booking.plotDetails) {
          sum +=
              double.tryParse(p.priceWithPlc) ?? double.tryParse(p.price) ?? 0;
        }
        if (sum == 0) return null;
        return '₹${sum.toStringAsFixed(2)}';
      }
      final parsed = double.tryParse(booking.totalAmount);
      if (parsed != null && parsed == 0) {
        return null;
      }
      if (booking.totalAmount.isEmpty || booking.totalAmount == '0') {
        return null;
      }
      return '₹${booking.totalAmount}';
    }();

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
          titleTextStyle: TextStyle(
            color: AppColors.primaryTextColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
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
              padding: EdgeInsets.all(isDesktopWeb ? 32.0 : 16.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isDesktopWeb ? 1200 : double.infinity,
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
                          } else if (status == 'completed' ||
                              status == 'sold') {
                            statusColor = Colors.green;
                            statusIcon = Icons.check_circle_outline;
                          } else if (status == 'pending' ||
                              status == 'processing') {
                            statusColor = Colors.orange;
                            statusIcon = Icons.pending_outlined;
                          } else {
                            statusColor = Colors.blue;
                            statusIcon = Icons.info_outline;
                          }

                          return Container(
                            padding: EdgeInsets.all(isDesktopWeb ? 20 : 16),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                isDesktopWeb ? 16 : 12,
                              ),
                              border: Border.all(
                                color: statusColor,
                                width: isDesktopWeb ? 1.5 : 1,
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
                                        fontSize: isDesktopWeb ? 15 : 14,
                                        color: AppColors.lightGreyColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: isDesktopWeb ? 6 : 4),
                                    Text(
                                      _formatStatusDisplay(
                                        booking.statusDisplay,
                                      ),
                                      style: TextStyle(
                                        fontSize: isDesktopWeb ? 20 : 18,
                                        fontWeight: FontWeight.w600,
                                        color: statusColor,
                                        letterSpacing: isDesktopWeb ? 0.3 : 0,
                                      ),
                                    ),
                                  ],
                                ),
                                Icon(
                                  statusIcon,
                                  color: statusColor,
                                  size: isDesktopWeb ? 36 : 32,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      SizedBox(height: isDesktopWeb ? 32 : 24),

                      // Plot Information Section
                      _buildSectionTitle('Plot Information'),
                      if (booking.plotDetails.isNotEmpty) ...[
                        PlotDetailsCard(
                          selectedPlots: booking.plotDetails
                              .map(
                                (p) => p.toPlot(
                                  projectId: booking.project?.id.toString(),
                                  roadWidthFront: booking.roadWidthFront,
                                  roadWidthBack: booking.roadWidthBack,
                                  roadWidthLeft: booking.roadWidthLeft,
                                  roadWidthRight: booking.roadWidthRight,
                                ),
                              )
                              .toList(),
                          selectedProjectName:
                              booking.project?.name ??
                              booking.plotDetails.first.projectName,
                        ),
                        SizedBox(height: isDesktopWeb ? 16 : 12),
                        _buildDetailCard([
                          _buildDetailRow('Payment Type', bookingTypeDisplay),
                          if (totalAmountDisplay != null)
                            _buildDetailRow('Total Amount', totalAmountDisplay),
                          _buildDetailRow(
                            'Booking Amount',
                            '₹${booking.bookingAmount}',
                          ),
                          _buildDetailRow('Booked At', booking.bookedAt),
                          // if (booking.plcApplied &&
                          //     booking.plcPercentage != null &&
                          //     booking.plcPercentage! > 0)
                          //   _buildDetailRow('PLC %', '${booking.plcPercentage}'),
                        ]),
                      ] else
                        _buildDetailCard([
                          Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: isDesktopWeb ? 24.0 : 16.0,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.location_off_outlined,
                                    size: isDesktopWeb ? 40 : 32,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No plot details available',
                                    style: TextStyle(
                                      fontSize: isDesktopWeb ? 15 : 14,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ]),
                      SizedBox(height: isDesktopWeb ? 32 : 24),

                      // Customer Information and Payment Information in a row for desktop web
                      if (isDesktopWeb)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionTitle('Customer Information'),
                                  _buildDetailCard([
                                    _buildDetailRow(
                                      'Customer Name',
                                      booking.customerName,
                                    ),
                                    _buildDetailRow(
                                      'Phone',
                                      booking.customerPhone,
                                    ),
                                    if (booking.customerEmail.isNotEmpty)
                                      _buildDetailRow(
                                        'Email',
                                        booking.customerEmail,
                                      ),
                                    if (booking.customerAddress.isNotEmpty)
                                      _buildDetailRow(
                                        'Address',
                                        booking.customerAddress,
                                      ),
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
                                    _buildDetailRow(
                                      'Payment Method',
                                      PaymentMethod.getValue(
                                            booking.paymentMode,
                                          ).isNotEmpty
                                          ? PaymentMethod.getValue(
                                              booking.paymentMode,
                                            )
                                          : booking.paymentMode,
                                    ),
                                    if (booking.paymentMode.toLowerCase() ==
                                            PaymentMethod.upi &&
                                        booking.paymentReference.isNotEmpty)
                                      _buildDetailRow(
                                        'UPI Transaction ID',
                                        booking.paymentReference,
                                      ),
                                    if (booking.chequeNumber.isNotEmpty)
                                      _buildDetailRow(
                                        'Cheque Number',
                                        booking.chequeNumber,
                                      ),
                                    if (booking.chequeDate != null &&
                                        booking.chequeDate!.isNotEmpty)
                                      _buildDetailRow(
                                        'Cheque Date',
                                        booking.chequeDate!,
                                      ),
                                    if (booking.paymentMode.toLowerCase() ==
                                            PaymentMethod.cheque &&
                                        booking.chequeCopy != null &&
                                        booking.chequeCopy!.isNotEmpty)
                                      _buildChequeCopyRow(
                                        'Cheque Copy',
                                        booking.chequeCopy!,
                                      ),
                                    if (booking.paymentMode.toLowerCase() ==
                                            PaymentMethod.rtgs &&
                                        booking.rtgsImage != null &&
                                        booking.rtgsImage!.isNotEmpty)
                                      _buildChequeCopyRow(
                                        'RTGS/NEFT Image',
                                        booking.rtgsImage!,
                                      ),
                                    if (booking.paymentDetails.isNotEmpty)
                                      _buildDetailRow(
                                        'Payment Details',
                                        booking.paymentDetails,
                                      ),
                                    if (!isWithoutLoan &&
                                        booking.loanAmount != null &&
                                        booking.loanAmount!.isNotEmpty)
                                      _buildDetailRow(
                                        'Loan Amount',
                                        '₹${booking.loanAmount!}',
                                      ),
                                    if (!isWithoutLoan &&
                                        booking.loanBankName != null &&
                                        booking.loanBankName!.isNotEmpty)
                                      _buildDetailRow(
                                        'Loan Bank',
                                        booking.loanBankName!,
                                      ),
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
                          _buildDetailRow(
                            'Customer Name',
                            booking.customerName,
                          ),
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
                          _buildDetailRow(
                            'Payment Method',
                            PaymentMethod.getValue(
                                  booking.paymentMode,
                                ).isNotEmpty
                                ? PaymentMethod.getValue(booking.paymentMode)
                                : booking.paymentMode,
                          ),
                          if (booking.paymentMode.toLowerCase() ==
                                  PaymentMethod.upi &&
                              booking.paymentReference.isNotEmpty)
                            _buildDetailRow(
                              'UPI Transaction ID',
                              booking.paymentReference,
                            ),

                          if (booking.paymentMode.toLowerCase() ==
                              PaymentMethod.upi &&
                              booking.upiImage != null &&
                              booking.upiImage!.isNotEmpty)
                            _buildChequeCopyRow(
                              'UPI Image',
                              booking.upiImage!,
                            ),

                          if (booking.chequeNumber.isNotEmpty)
                            _buildDetailRow(
                              'Cheque Number',
                              booking.chequeNumber,
                            ),
                          if (booking.chequeDate != null &&
                              booking.chequeDate!.isNotEmpty)
                            _buildDetailRow('Cheque Date', booking.chequeDate!),
                          if (booking.paymentMode.toLowerCase() ==
                                  PaymentMethod.cheque &&
                              booking.chequeCopy != null &&
                              booking.chequeCopy!.isNotEmpty)
                            _buildChequeCopyRow(
                              'Cheque Copy',
                              booking.chequeCopy!,
                            ),
                          if (booking.paymentMode.toLowerCase() ==
                                  PaymentMethod.rtgs &&
                              booking.rtgsImage != null &&
                              booking.rtgsImage!.isNotEmpty)
                            _buildChequeCopyRow(
                              'RTGS/NEFT Image',
                              booking.rtgsImage!,
                            ),
                          if (booking.paymentDetails.isNotEmpty)
                            _buildDetailRow(
                              'Payment Details',
                              booking.paymentDetails,
                            ),
                          if (!isWithoutLoan &&
                              booking.loanAmount != null &&
                              booking.loanAmount!.isNotEmpty)
                            _buildDetailRow(
                              'Loan Amount',
                              '₹${booking.loanAmount!}',
                            ),
                          if (!isWithoutLoan &&
                              booking.loanBankName != null &&
                              booking.loanBankName!.isNotEmpty)
                            _buildDetailRow('Loan Bank', booking.loanBankName!),
                        ]),
                      ],
                      SizedBox(height: isDesktopWeb ? 32 : 24),

                      //Document Information Section
                      _buildSectionTitle('Document Information'),
                      _buildDetailCard([
                        _buildDetailRow('PAN Card', booking.panCard),
                        _buildDetailRow('Aadhar Card', booking.aadharCard),
                        if (booking.salaryIndividual &&
                            booking.salarySlip != null &&
                            booking.salarySlip!.isNotEmpty)
                          _buildDocumentRow(
                            context,
                            'Salary Slip',
                            booking.salarySlip!,
                          ),
                        if (booking.salaryIndividual &&
                            booking.form16a != null &&
                            booking.form16a!.isNotEmpty)
                          _buildDocumentRow(
                            context,
                            'Form 16A',
                            booking.form16a!,
                          ),
                        if (booking.bankStatement != null &&
                            booking.bankStatement!.isNotEmpty)
                          _buildDocumentRow(
                            context,
                            'Bank Statement',
                            booking.bankStatement!,
                          ),
                        /*if (booking.otherDocuments != null &&
                            booking.otherDocuments!.isNotEmpty)
                          _buildDocumentRow(
                            context,
                            'Other Documents',
                            booking.otherDocuments!,
                          ),*/
                      ]),
                      SizedBox(height: isDesktopWeb ? 32 : 24),

                      // Bank Details Section
                      // _buildSectionTitle('Bank Details'),
                      // _buildDetailCard([
                      //   _buildDetailRow('Account Holder Name', booking.accountHolderName),
                      //   _buildDetailRow('Branch Name', booking.branchName),
                      //   _buildDetailRow('Account Number', booking.accountNumber),
                      //   _buildDetailRow('IFSC Code', booking.ifscCode),
                      //   _buildDetailRow('Account Type', booking.accountType),
                      //   _buildDetailRow('Bank Contact', booking.bankContactNumber),
                      // ]),
                      //SizedBox(height: isDesktopWeb ? 32 : 24),

                      // Remarks Section
                      if (booking.remarks.isNotEmpty) ...[
                        _buildSectionTitle('Remarks'),
                        _buildDetailCard([
                          _buildDetailRow('Notes', booking.remarks),
                        ]),
                        SizedBox(height: isDesktopWeb ? 32 : 24),
                      ],

                      // Documents Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: _buildSectionTitle(
                              'Documents (${booking.documentCount})',
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.edit,
                              color: AppColors.primaryColor,
                            ),
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      BookingDocumentManagementScreen(
                                        booking: booking,
                                      ),
                                ),
                              );
                              if (result == true && mounted) {
                                await _refreshBookingData();
                              }
                            },
                            tooltip: 'Manage Documents',
                          ),
                        ],
                      ),
                      if (booking.documents.isNotEmpty)
                        _buildDocumentsGrid(booking.documents)
                      else
                        _buildNoDocumentsMessage(),
                      SizedBox(height: isDesktopWeb ? 32 : 24),

                      // Cancellation Information (if cancelled)
                      if (booking.cancelledAt != null &&
                          booking.cancelledAt!.isNotEmpty) ...[
                        _buildSectionTitle('Cancellation Information'),
                        _buildDetailCard([
                          _buildDetailRow('Cancelled At', booking.cancelledAt!),
                          if (booking.cancelledBy != null &&
                              booking.cancelledBy!.isNotEmpty)
                            _buildDetailRow(
                              'Cancelled By',
                              booking.cancelledBy!,
                            ),
                          if (booking.cancellationReason != null &&
                              booking.cancellationReason!.isNotEmpty)
                            _buildDetailRow(
                              'Cancellation Reason',
                              booking.cancellationReason!,
                            ),
                        ]),
                        SizedBox(height: isDesktopWeb ? 32 : 24),
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
    final isDesktopWeb = _isDesktopWeb(context);
    return Padding(
      padding: EdgeInsets.only(bottom: isDesktopWeb ? 16.0 : 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: isDesktopWeb ? 22 : 20,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryTextColor,
          letterSpacing: isDesktopWeb ? 0.5 : 0,
        ),
      ),
    );
  }

  Widget _buildDetailCard(List<Widget> children) {
    final isDesktopWeb = _isDesktopWeb(context);
    return Container(
      padding: EdgeInsets.all(isDesktopWeb ? 24 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isDesktopWeb ? 16 : 12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: isDesktopWeb ? 0.08 : 0.1),
            spreadRadius: isDesktopWeb ? 0 : 1,
            blurRadius: isDesktopWeb ? 8 : 4,
            offset: Offset(0, isDesktopWeb ? 4 : 2),
          ),
        ],
        border: isDesktopWeb
            ? Border.all(color: Colors.grey.withValues(alpha: 0.1), width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isLink = false}) {
    final isDesktopWeb = _isDesktopWeb(context);
    return Padding(
      padding: EdgeInsets.only(bottom: isDesktopWeb ? 16.0 : 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: isDesktopWeb ? 180 : 140,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: isDesktopWeb ? 15 : 14,
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
                        fontSize: isDesktopWeb ? 15 : 14,
                        color: Colors.blue,
                        fontWeight: FontWeight.w400,
                        decoration: TextDecoration.underline,
                        height: isDesktopWeb ? 1.5 : 1.4,
                      ),
                    ),
                  )
                : Text(
                    value.isNotEmpty ? value : '-',
                    style: TextStyle(
                      fontSize: isDesktopWeb ? 15 : 14,
                      color: AppColors.primaryTextColor,
                      fontWeight: FontWeight.w400,
                      height: isDesktopWeb ? 1.5 : 1.4,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentRow(BuildContext context, String label, String url) {
    final isDesktopWeb = _isDesktopWeb(context);
    // Extract filename from URL
    String fileName = url.split('/').last;
    if (fileName.contains('?')) {
      fileName = fileName.split('?').first;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: isDesktopWeb ? 16.0 : 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: isDesktopWeb ? 180 : 140,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: isDesktopWeb ? 15 : 14,
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
                      fontSize: isDesktopWeb ? 15 : 14,
                      color: AppColors.primaryTextColor,
                      fontWeight: FontWeight.w400,
                      height: isDesktopWeb ? 1.5 : 1.4,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: isDesktopWeb ? 12 : 8),
                SizedBox(
                  width: isDesktopWeb ? 36 : 32,
                  height: isDesktopWeb ? 36 : 32,
                  child: IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              WebViewScreen(url: url, title: label),
                        ),
                      );
                    },
                    icon: Icon(Icons.visibility, size: isDesktopWeb ? 22 : 20),
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

  Widget _buildChequeCopyRow(String label, String imageUrl) {
    final isDesktopWeb = _isDesktopWeb(context);

    return Padding(
      padding: EdgeInsets.only(bottom: isDesktopWeb ? 16.0 : 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isDesktopWeb ? 180 : 140,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: isDesktopWeb ? 15 : 14,
                color: AppColors.lightGreyColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _openDocument(imageUrl),
              child: Container(
                height: isDesktopWeb ? 120 : 96,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.25),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: kIsWeb
                      ? WebImageWidget(
                          imageUrl: imageUrl,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          borderRadius: 1,
                        )
                      : Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.grey[500],
                              size: isDesktopWeb ? 30 : 26,
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsGrid(
    List<booking_document_model.BookingDocument> documents,
  ) {
    final isDesktopWeb = _isDesktopWeb(context);
    return Container(
      padding: EdgeInsets.all(isDesktopWeb ? 24 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isDesktopWeb ? 16 : 12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: isDesktopWeb ? 0.08 : 0.1),
            spreadRadius: isDesktopWeb ? 0 : 1,
            blurRadius: isDesktopWeb ? 8 : 4,
            offset: Offset(0, isDesktopWeb ? 4 : 2),
          ),
        ],
        border: isDesktopWeb
            ? Border.all(color: Colors.grey.withValues(alpha: 0.1), width: 1)
            : null,
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isDesktopWeb ? 4 : 2,
          crossAxisSpacing: isDesktopWeb ? 16 : 12,
          mainAxisSpacing: isDesktopWeb ? 16 : 12,
          childAspectRatio: isDesktopWeb ? 0.85 : 0.9,
        ),
        itemCount: documents.length,
        itemBuilder: (context, index) {
          return _buildDocumentThumbnail(documents[index]);
        },
      ),
    );
  }

  Widget _buildNoDocumentsMessage() {
    final isDesktopWeb = _isDesktopWeb(context);
    return Container(
      padding: EdgeInsets.all(isDesktopWeb ? 24 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isDesktopWeb ? 16 : 12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: isDesktopWeb ? 0.08 : 0.1),
            spreadRadius: isDesktopWeb ? 0 : 1,
            blurRadius: isDesktopWeb ? 8 : 4,
            offset: Offset(0, isDesktopWeb ? 4 : 2),
          ),
        ],
        border: isDesktopWeb
            ? Border.all(color: Colors.grey.withValues(alpha: 0.1), width: 1)
            : null,
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: isDesktopWeb ? 32 : 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.description_outlined,
                size: isDesktopWeb ? 48 : 40,
                color: Colors.grey[400],
              ),
              SizedBox(height: isDesktopWeb ? 12 : 8),
              Text(
                'No documents uploaded',
                style: TextStyle(
                  fontSize: isDesktopWeb ? 16 : 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentThumbnail(
    booking_document_model.BookingDocument document,
  ) {
    final isDesktopWeb = _isDesktopWeb(context);
    final isPdf =
        document.documentUrl.toLowerCase().endsWith('.pdf') ||
        document.filetype.toLowerCase() == 'pdf';
    final isImage =
        document.documentUrl.toLowerCase().endsWith('.jpg') ||
        document.documentUrl.toLowerCase().endsWith('.jpeg') ||
        document.documentUrl.toLowerCase().endsWith('.png') ||
        document.documentUrl.toLowerCase().endsWith('.gif') ||
        document.filetype.toLowerCase() == 'image';

    return GestureDetector(
      onTap: () => _openDocument(document.documentUrl),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isDesktopWeb ? 12 : 8),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 0,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thumbnail Preview
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(isDesktopWeb ? 12 : 8),
                ),
                child: Stack(
                  children: [
                    Container(
                      color: Colors.grey.withValues(alpha: 0.1),
                      child: isImage
                          ? kIsWeb
                                ? WebImageWidget(
                                    imageUrl: document.documentUrl,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                    borderRadius: 1,
                                  )
                                : Image.network(
                                    document.documentUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[200],
                                        child: Center(
                                          child: Icon(
                                            Icons.image_not_supported,
                                            size: 32,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                      );
                                    },
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        color: Colors.grey[200],
                                        child: Center(
                                          child: SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.primaryColor,
                                              value:
                                                  loadingProgress
                                                          .expectedTotalBytes !=
                                                      null
                                                  ? loadingProgress
                                                            .cumulativeBytesLoaded /
                                                        loadingProgress
                                                            .expectedTotalBytes!
                                                  : null,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  )
                          : isPdf
                          ? Container(
                              color: Colors.red[50],
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.picture_as_pdf,
                                      size: isDesktopWeb ? 40 : 36,
                                      color: Colors.red[400],
                                    ),
                                    SizedBox(height: isDesktopWeb ? 6 : 4),
                                    Text(
                                      'PDF',
                                      style: TextStyle(
                                        fontSize: isDesktopWeb ? 11 : 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.red[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Container(
                              color: Colors.grey[200],
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.insert_drive_file,
                                      size: isDesktopWeb ? 40 : 36,
                                      color: Colors.grey[600],
                                    ),
                                    SizedBox(height: isDesktopWeb ? 6 : 4),
                                    Text(
                                      'File',
                                      style: TextStyle(
                                        fontSize: isDesktopWeb ? 11 : 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                    // Transparent overlay to capture taps on web images
                    if (isImage && kIsWeb)
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: () => _openDocument(document.documentUrl),
                          behavior: HitTestBehavior.opaque,
                          child: Container(color: Colors.transparent),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Document Info
            Padding(
              padding: EdgeInsets.all(isDesktopWeb ? 10 : 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isPdf
                            ? Icons.picture_as_pdf
                            : isImage
                            ? Icons.image
                            : Icons.insert_drive_file,
                        size: isDesktopWeb ? 14 : 12,
                        color: isPdf
                            ? Colors.red
                            : isImage
                            ? AppColors.primaryColor
                            : AppColors.primaryColor,
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          document.filetypeDisplay.isNotEmpty
                              ? document.filetypeDisplay
                              : (isPdf
                                    ? 'PDF'
                                    : isImage
                                    ? 'Image'
                                    : 'Document'),
                          style: TextStyle(
                            fontSize: isDesktopWeb ? 11 : 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryTextColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (document.description.isNotEmpty) ...[
                    SizedBox(height: 4),
                    Text(
                      document.description,
                      style: TextStyle(
                        fontSize: isDesktopWeb ? 10 : 9,
                        color: AppColors.lightGreyColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDocument(String url) async {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document URL is not available')),
      );
      return;
    }

    try {
      final uri = Uri.parse(url);

      // Check if it's a PDF or image
      final isPdf = url.toLowerCase().endsWith('.pdf');
      final isImage =
          url.toLowerCase().endsWith('.jpg') ||
          url.toLowerCase().endsWith('.jpeg') ||
          url.toLowerCase().endsWith('.png') ||
          url.toLowerCase().endsWith('.gif');

      // Check if it's a mobile browser (web but mobile screen size)
      final isMobileBrowser = kIsWeb && Responsive.isMobile(context);

      if (kIsWeb && !isMobileBrowser) {
        // On desktop web, open in new tab
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to open document')),
          );
        }
      } else {
        // On mobile browser or native mobile app
        if (isImage) {
          // Show full-screen image viewer for images
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => _FullScreenImagePage(imageUrl: url),
            ),
          );
        } else if (isPdf) {
          // Use WebView for PDFs
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WebViewScreen(url: url, title: 'Document'),
            ),
          );
        } else {
          // Open other files in browser
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Unable to open document')),
            );
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error opening document: $e')));
    }
  }
}

// Full screen image viewer page
class _FullScreenImagePage extends StatelessWidget {
  final String imageUrl;

  const _FullScreenImagePage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Image Preview',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          // Full screen image viewer with zoom and pan
          InteractiveViewer(
            minScale: 0.5,
            maxScale: 5.0,
            panEnabled: true,
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: kIsWeb
                  ? WebImageWidget(
                      imageUrl: imageUrl,
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                      fit: BoxFit.contain,
                      borderRadius: 1,
                    )
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.black,
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 60,
                                  color: Colors.white70,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Failed to load image',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.black,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(
                                  color: Colors.white70,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Loading image...',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
