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

    final plot = selectedPlot!;
    final saleableSize = plot.saleableSize;
    final saleableSizeValue = saleableSize ?? 0;
    final hasSaleableSize = saleableSize != null && saleableSize > 0;
    final priceWithPlc = plot.priceWithPlc;
    final showPlcBreakup =
        priceWithPlc != null && priceWithPlc > 0 && priceWithPlc != plot.price;
    final plcLabel = plot.plcApplied ? 'PLC Applied' : 'PLC Available';
    final showPlcSummary = plot.plcApplied && plot.priceWithPlc != null;

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
                  _DetailItem('Dimensions:', plot.dimensions),
                  _DetailItem('Area:', '${plot.area.toInt()} sq ft'),
                  if (hasSaleableSize)
                    _DetailItem(
                      'Saleable Size:',
                      '${saleableSizeValue.toStringAsFixed(0)} sq ft',
                    ),
                  _DetailItem(
                    showPlcBreakup ? 'Price (with PLC):' : 'Price:',
                    '₹${plot.effectivePrice.toInt()}',
                    isHighlighted: true,
                  ),
                  if (showPlcBreakup)
                    _DetailItem(
                      'Base Price:',
                      '₹${plot.price.toInt()}',
                    ),
                ]),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildDetailColumn([
                  _DetailItem('Plot number:', plot.plotNumber),
                  _DetailItem('Facing:', plot.facing),
                  _DetailItem('Remark:', plot.remark),
                  if (plot.plc || plot.plcApplied)
                    _DetailItem(plcLabel, plot.plc || plot.plcApplied ? 'Yes' : 'No'),
                  if (plot.status.isNotEmpty)
                    _DetailItem('Status:', plot.status),
                ]),
              ),
            ],
          ),
          if (showPlcSummary) ...[
            const SizedBox(height: 24),
            _buildPlcSummary(plot),
          ],
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

  Widget _buildPlcSummary(Plot plot) {
    final basePrice = plot.price;
    final finalPrice = plot.priceWithPlc ?? basePrice;
    final plcPercent = plot.plcPercentage ?? 0;
    final badgeText = '${plcPercent.toStringAsFixed(2)}% Applied';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.lightGreyBorderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'PLC:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.headingTextColor,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.successColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.successColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Final Price:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.headingTextColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '₹${finalPrice.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '(Base ₹${basePrice.toStringAsFixed(2)} + ${plcPercent.toStringAsFixed(2)}% PLC)',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.darkGreyColor,
            ),
          ),
        ],
      ),
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
