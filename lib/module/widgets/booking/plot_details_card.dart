import 'package:flutter/material.dart';
import '../../../config/constant/app_colors.dart';
import '../../../data/models/project_model.dart';

class PlotDetailsCard extends StatelessWidget {
  final Plot? selectedPlot;
  final String? selectedProjectName;

  const PlotDetailsCard({
    super.key,
    this.selectedPlot,
    this.selectedProjectName,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedPlot == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      // padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        // border: Border.all(
        //   color: AppColors.lightGreyBorderColor,
        //   width: 1,
        // ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Plot Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.headingTextColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDetailColumn([
                  _DetailItem('Project:', selectedProjectName ?? ''),
                  _DetailItem('Dimensions:', selectedPlot!.dimensions),
                  _DetailItem('Area:', '${selectedPlot!.area.toInt()} sq ft'),
                  _DetailItem('Price:', '\$${selectedPlot!.price.toInt()}', isHighlighted: true),
                ]),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildDetailColumn([
                  _DetailItem('Plot number:', selectedPlot!.plotNumber),
                  _DetailItem('Facing:', selectedPlot!.facing),
                  _DetailItem('Remark:', selectedPlot!.remark),
                  const _DetailItem('', ''), // Empty item for spacing
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailColumn(List<_DetailItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) => _buildDetailRow(item)).toList(),
    );
  }

  Widget _buildDetailRow(_DetailItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.label,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.darkGreyColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: item.isHighlighted 
                  ? AppColors.primaryColor 
                  : AppColors.textColor,
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
