import 'package:flutter/material.dart';
import 'package:highfly/config/constant/app_colors.dart';
import 'package:highfly/data/models/hold_list_model.dart';
import '../../global/widgets/common_app_bar.dart';

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

class HoldDetailScreen extends StatelessWidget {
  final HoldListModel hold;

  const HoldDetailScreen({super.key, required this.hold});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: commonAppBar(context, "Hold Details"),
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
                
                final status = hold.status.toLowerCase();
                
                // Check status first, then isExpired flag
                if (status == 'active') {
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
                            _formatStatusDisplay(hold.statusDisplay),
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
              _buildDetailRow('Plot No.', hold.plotCode),
              _buildDetailRow('Hold Amount', '₹${hold.holdAmount}'),
              _buildDetailRow('Hold Until', hold.holdUntil),
              _buildDetailRow('Created At', hold.createdAt),
              _buildDetailRow('Updated At', hold.updatedAt),
            ]),
            const SizedBox(height: 24),

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
            const SizedBox(height: 24),

            // Payment Information Section
            _buildSectionTitle('Payment Information'),
            _buildDetailCard([
              _buildDetailRow('Payment Mode', hold.paymentMode),
              _buildDetailRow('Payment Reference', hold.paymentReference),
            ]),
            const SizedBox(height: 24),

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
            const SizedBox(height: 24),

            // Remarks Section
            if (hold.remarks.isNotEmpty) ...[
              _buildSectionTitle('Remarks'),
              _buildDetailCard([
                _buildDetailRow('Notes', hold.remarks),
              ]),
              const SizedBox(height: 24),
            ],

            // Additional Information
            _buildSectionTitle('Additional Information'),
            _buildDetailCard([
              _buildDetailRow('Agent Name', hold.agentName),
              _buildDetailRow('Created By', hold.createdBy),
              _buildDetailRow('Updated By', hold.updatedBy),
            ]),
            const SizedBox(height: 24),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
            child: Text(
              value.isNotEmpty ? value : 'N/A',
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
}

