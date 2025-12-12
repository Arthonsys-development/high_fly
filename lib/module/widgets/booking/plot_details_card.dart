import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
    final plc = plot.plc ? 'Yes' : 'No';
    final showPlcSummary = plot.plcApplied && plot.priceWithPlc != null;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(kIsWeb ? 24 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kIsWeb ? 12 : 12),
        border: kIsWeb ? Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ) : null,
        boxShadow: kIsWeb ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Plot Details',
            style: TextStyle(
              fontSize: kIsWeb ? 18 : 16,
              fontWeight: FontWeight.w600,
              color: AppColors.headingTextColor,
            ),
          ),
          SizedBox(height: kIsWeb ? 20 : 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              SizedBox(width: kIsWeb ? 32 : 20),
              Expanded(
                child: _buildDetailColumn([
                  _DetailItem('Plot number:', plot.plotNumber),
                  _DetailItem('Facing:', plot.facing),
                  if (plot.remark.isNotEmpty)
                    _DetailItem('Remark:', plot.remark),
                  _DetailItem('Plc:', plc),
                  if (plot.plc || plot.plcApplied)
                    _DetailItem(plcLabel, plot.plc || plot.plcApplied ? 'Yes' : 'No'),
                  if (plot.status.isNotEmpty)
                    _DetailItem('Status:', plot.status),
                ]),
              ),
            ],
          ),
          if (showPlcSummary) ...[
            SizedBox(height: kIsWeb ? 28 : 24),
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
      padding: EdgeInsets.all(kIsWeb ? 20 : 16),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.02),
        borderRadius: BorderRadius.circular(kIsWeb ? 12 : 12),
        border: Border.all(
          color: AppColors.lightGreyBorderColor,
          width: kIsWeb ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'PLC:',
                style: TextStyle(
                  fontSize: kIsWeb ? 18 : 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.headingTextColor,
                ),
              ),
              SizedBox(width: kIsWeb ? 16 : 12),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: kIsWeb ? 14 : 12,
                  vertical: kIsWeb ? 6 : 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.successColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: kIsWeb ? 13 : 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.successColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: kIsWeb ? 20 : 16),
          Text(
            'Final Price:',
            style: TextStyle(
              fontSize: kIsWeb ? 18 : 16,
              fontWeight: FontWeight.w600,
              color: AppColors.headingTextColor,
            ),
          ),
          SizedBox(height: kIsWeb ? 8 : 6),
          Text(
            '₹${finalPrice.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: kIsWeb ? 28 : 22,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryColor,
            ),
          ),
          SizedBox(height: kIsWeb ? 6 : 4),
          Text(
            '(Base ₹${basePrice.toStringAsFixed(2)} + ${plcPercent.toStringAsFixed(2)}% PLC)',
            style: TextStyle(
              fontSize: kIsWeb ? 15 : 14,
              color: AppColors.darkGreyColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(_DetailItem item) {
    return Padding(
      padding: EdgeInsets.only(bottom: kIsWeb ? 16 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.label,
            style: TextStyle(
              fontSize: kIsWeb ? 15 : 16,
              color: AppColors.darkGreyColor,
              fontWeight: kIsWeb ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
          SizedBox(height: kIsWeb ? 6 : 4),
          Text(
            item.value,
            style: TextStyle(
              fontSize: kIsWeb ? 17 : 16,
              fontWeight: item.isHighlighted ? FontWeight.w600 : FontWeight.w400,
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
