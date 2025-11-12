import 'package:flutter/material.dart';
import '../../../config/constant/app_colors.dart';
import '../../../data/models/customer_model.dart';

class CustomerDetailsCard extends StatelessWidget {
  final Customer? selectedCustomer;

  const CustomerDetailsCard({
    super.key,
    this.selectedCustomer,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
    // if (selectedCustomer == null) {
    //   return const SizedBox.shrink();
    // }

    // return Container(
    //   width: double.infinity,
    //   padding: const EdgeInsets.all(20),
    //   decoration: BoxDecoration(
    //     color: Colors.white,
    //     borderRadius: BorderRadius.circular(12),
    //     border: Border.all(
    //       color: AppColors.lightGreyBorderColor,
    //       width: 1,
    //     ),
    //   ),
    //   child: Column(
    //     crossAxisAlignment: CrossAxisAlignment.start,
    //     children: [
    //       const Text(
    //         'Customer Details',
    //         style: TextStyle(
    //           fontSize: 18,
    //           fontWeight: FontWeight.bold,
    //           color: AppColors.headingTextColor,
    //         ),
    //       ),
    //       const SizedBox(height: 16),
    //       Row(
    //         children: [
    //           Expanded(
    //             child: _buildDetailColumn([
    //               _DetailItem('Email', selectedCustomer!.email ?? 'Not provided'),
    //               _DetailItem('Phone', selectedCustomer!.phone),
    //               _DetailItem('Location', selectedCustomer!.location ?? 'Not provided'),
    //               _DetailItem('Budget', selectedCustomer!.budget ?? 'Not specified', isHighlighted: true),
    //             ]),
    //           ),
    //           const SizedBox(width: 20),
    //           Expanded(
    //             child: _buildDetailColumn([
    //               const _DetailItem('', ''), // Empty item for spacing
    //               const _DetailItem('', ''), // Empty item for spacing
    //               const _DetailItem('', ''), // Empty item for spacing
    //               const _DetailItem('', ''), // Empty item for spacing
    //             ]),
    //           ),
    //         ],
    //       ),
    //     ],
    //   ),
    // );
  }

  Widget _buildDetailColumn(List<_DetailItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) => _buildDetailRow(item)).toList(),
    );
  }

  Widget _buildDetailRow(_DetailItem item) {
    if (item.label.isEmpty) {
      return const SizedBox(height: 48); // Empty space for alignment
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.darkGreyColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: item.isHighlighted 
                  ? AppColors.primaryColor 
                  : AppColors.headingTextColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailItem {
  final String label;
  final String value;
  final bool isHighlighted;

  const _DetailItem(this.label, this.value, {this.isHighlighted = false});
}
