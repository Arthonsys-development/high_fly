import 'package:flutter/material.dart';
import '../../../config/constant/app_colors.dart';
import '../../../config/constant/const_assets.dart';
import '../../../data/models/booking_summary_model.dart';
import 'header_icon_widget.dart';
import 'action_buttons.dart';

class ReviewConfirmSection extends StatefulWidget {
  final String title;
  final String nextButtonText;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final BookingSummary bookingSummary;

  const ReviewConfirmSection({
    super.key,
    required this.title,
    required this.nextButtonText,
    this.onPrevious,
    required this.onNext,
    required this.bookingSummary,
  });

  @override
  State<ReviewConfirmSection> createState() => _ReviewConfirmSectionState();
}

class _ReviewConfirmSectionState extends State<ReviewConfirmSection> {
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
            icon: Icons.person,
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
            icon: Icons.location_on,
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
                '\$${widget.bookingSummary.selectedPlot?.price ?? 'N/A'}',
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Payment Information Card
          _buildInfoCard(
            icon: Icons.payment,
            iconColor: AppColors.primaryColor,
            title: 'Payment Information',
            children: [
              _buildInfoRow(
                'Amount',
                '\$${widget.bookingSummary.paymentDetails?.paymentAmount ?? 'N/A'}',
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
          
          // Bank Details Card
          _buildInfoCard(
            icon: Icons.account_balance,
            iconColor: Colors.brown,
            title: 'Bank Details',
            children: [
              _buildInfoRow(
                'Account Holder Name',
                widget.bookingSummary.bankDetails?.accountHolderName ?? 'N/A',
              ),
              _buildInfoRow(
                'Bank Name',
                'HDFC Bank', // This would come from bank details in a real app
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
            onNext: widget.onNext,
            nextButtonText: widget.nextButtonText,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
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
              Container(
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
              ),
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
}
