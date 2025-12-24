import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:highfly/config/constant/app_colors.dart';
import 'package:highfly/data/models/hold_list_model.dart';
import 'package:highfly/data/models/payment_model.dart';
import '../../providers/holds_provider.dart';
import 'hold_booking_screen.dart';
import 'hold_edit_screen.dart';

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

class HoldDetailScreen extends ConsumerStatefulWidget {
  final HoldListModel hold;

  const HoldDetailScreen({super.key, required this.hold});

  @override
  ConsumerState<HoldDetailScreen> createState() => _HoldDetailScreenState();
}

class _HoldDetailScreenState extends ConsumerState<HoldDetailScreen> {
  late HoldListModel _currentHold;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentHold = widget.hold;
  }

  Future<void> _refreshHoldData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Refresh holds list from provider
      await ref.read(holdsControllerProvider.notifier).loadHolds();
      
      // Find the updated hold in the list
      final holds = ref.read(holdsControllerProvider).holds;
      final updatedHold = holds.firstWhere(
        (h) => h.id == _currentHold.id,
        orElse: () => _currentHold,
      );

      if (mounted) {
        setState(() {
          _currentHold = updatedHold;
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
        builder: (context) => HoldEditScreen(hold: _currentHold),
      ),
    );

    // If update was successful, refresh the data
    if (result == true && mounted) {
      await _refreshHoldData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hold = _currentHold;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          title: const Text("Hold Details"),
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
            if (hold.status.toLowerCase() == 'active' && !hold.isExpired)
              IconButton(
                icon: const Icon(Icons.edit, color: AppColors.primaryColor),
                onPressed: _isLoading ? null : _navigateToEdit,
                tooltip: 'Edit Hold',
              ),
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
                      
                      final status = hold.status.toLowerCase();
                      final statusDisplay = hold.statusDisplay.toLowerCase();
                      
                      // Check for "Converted to Booking" status first
                      if (statusDisplay == 'converted to booking') {
                        statusColor = Colors.blue;
                        statusIcon = Icons.check_circle;
                      } else if (status == 'active') {
                        statusColor = Colors.green;
                        statusIcon = Icons.check_circle_outline;
                      } else if (status == 'expired' || status == 'inactive' || hold.isExpired) {
                        statusColor = Colors.red;
                        statusIcon = Icons.error_outline;
                      } else {
                        statusColor = Colors.orange;
                        statusIcon = Icons.pending_outlined;
                      }
                      
                      return Container(
                        padding: EdgeInsets.all(kIsWeb ? 20 : 16),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
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
                                  _formatStatusDisplay(hold.statusDisplay),
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
                    _buildDetailRow('Plot No.', hold.plotCode),
                    if (hold.project != null)
                      _buildDetailRow('Project', hold.project!.name),
                    if (hold.plotSize != null && hold.plotSize!.isNotEmpty)
                      _buildDetailRow('Plot Size', hold.plotSize!),
                    if (hold.plotArea != null && hold.plotArea!.isNotEmpty)
                      _buildDetailRow('Plot Area', '${hold.plotArea} sq ft'),
                    if (hold.plotPrice != null && hold.plotPrice!.isNotEmpty)
                      _buildDetailRow('Plot Price', '₹${hold.plotPrice}'),
                    if (hold.plotFacing != null && hold.plotFacing!.isNotEmpty)
                      _buildDetailRow('Plot Facing', hold.plotFacing!),
                  //  _buildDetailRow('Hold Amount', '₹${hold.holdAmount}'),
                    _buildDetailRow('Hold Until', hold.holdUntil),
                    _buildDetailRow('Created At', hold.createdAt),
                    _buildDetailRow('Updated At', hold.updatedAt),
                  ]),
                  SizedBox(height: kIsWeb ? 32 : 24),

                  // Customer Information and Hold Details in a row for web
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
                                _buildDetailRow('Customer Name', hold.customerName),
                                _buildDetailRow('Phone', hold.customerPhone),
                                if (hold.customerEmail.isNotEmpty)
                                  _buildDetailRow('Email', hold.customerEmail),
                              ]),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('Hold Details'),
                              _buildDetailCard([
                                _buildDetailRow('RERA Number', hold.reraNumber),
                                if (hold.teamLeaderName.isNotEmpty)
                                  _buildDetailRow('Team Leader', hold.teamLeaderName),
                                _buildDetailRow('Client Aadhar', hold.clientAadhar),
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
                      _buildDetailRow('Customer Name', hold.customerName),
                      _buildDetailRow('Phone', hold.customerPhone),
                      if (hold.customerEmail.isNotEmpty)
                        _buildDetailRow('Email', hold.customerEmail),
                    ]),
                    const SizedBox(height: 24),

                    // Hold Details Section
                    _buildSectionTitle('Hold Details'),
                    _buildDetailCard([
                      _buildDetailRow('RERA Number', hold.reraNumber),
                      if (hold.teamLeaderName.isNotEmpty)
                        _buildDetailRow('Team Leader', hold.teamLeaderName),
                      _buildDetailRow('Client Aadhar', hold.clientAadhar),
                    ]),
                  ],
                  SizedBox(height: kIsWeb ? 32 : 24),

                  // Payment Information Section
                  _buildSectionTitle('Payment Information'),
                  _buildDetailCard([
                    _buildDetailRow('Payment Mode', PaymentMethod.getValue(hold.paymentMode).isNotEmpty 
                        ? PaymentMethod.getValue(hold.paymentMode) 
                        : hold.paymentMode),
                    _buildDetailRow('Payment Reference', hold.paymentReference),
                  ]),
                  SizedBox(height: kIsWeb ? 32 : 24),

                  // Bank Details Section
                  _buildSectionTitle('Bank Details'),
                  _buildDetailCard([
                    _buildDetailRow('Account Holder Name', hold.accountHolderName),
                    _buildDetailRow('Branch Name', hold.branchName),
                    _buildDetailRow('Account Number', hold.accountNumber),
                    _buildDetailRow('IFSC Code', hold.ifscCode),
                    _buildDetailRow('Account Type', hold.accountType),
                    _buildDetailRow('Bank Contact', hold.bankContactNumber),
                  ]),
                  SizedBox(height: kIsWeb ? 32 : 24),

                  // Remarks Section
                  if (hold.remarks.isNotEmpty) ...[
                    _buildSectionTitle('Remarks'),
                    _buildDetailCard([
                      _buildDetailRow('Notes', hold.remarks),
                    ]),
                    SizedBox(height: kIsWeb ? 32 : 24),
                  ],

                  // Additional Information
                  // _buildSectionTitle('Additional Information'),
                  // _buildDetailCard([
                  //   _buildDetailRow('Agent Name', hold.agentName),
                  //   _buildDetailRow('Created By', hold.createdBy),
                  //   _buildDetailRow('Updated By', hold.updatedBy),
                  // ]),
                  // const SizedBox(height: 24),

                  // Book Now Button (only show if hold is active)
                  if (hold.status.toLowerCase() == 'active' && !hold.isExpired)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: kIsWeb ? 24.0 : 16.0),
                      child: SizedBox(
                        width: kIsWeb ? 300 : double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HoldBookingScreen(hold: hold),
                              ),
                            );

                            // If booking was successful, refresh the hold data
                            if (result == true && mounted) {
                              await _refreshHoldData();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            padding: EdgeInsets.symmetric(
                              vertical: kIsWeb ? 18 : 16,
                              horizontal: kIsWeb ? 32 : 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(kIsWeb ? 12 : 8),
                            ),
                            elevation: kIsWeb ? 2 : 1,
                          ),
                          child: Text(
                            'Book Now',
                            style: TextStyle(
                              fontSize: kIsWeb ? 16 : 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
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
            color: Colors.grey.withOpacity(kIsWeb ? 0.08 : 0.1),
            spreadRadius: kIsWeb ? 0 : 1,
            blurRadius: kIsWeb ? 8 : 4,
            offset: Offset(0, kIsWeb ? 4 : 2),
          ),
        ],
        border: kIsWeb ? Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: kIsWeb ? 16.0 : 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
            child: Text(
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
}

