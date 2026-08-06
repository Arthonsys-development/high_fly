import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../config/constant/app_colors.dart';
import '../../../data/models/project_model.dart';

class PlotDetailsCard extends StatelessWidget {
  final List<Plot>? selectedPlots;
  final String? selectedProjectName;
  final bool hidePlotPricing;

  const PlotDetailsCard({
    super.key,
    this.selectedPlots,
    this.selectedProjectName,
    this.hidePlotPricing = false,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedPlots == null || selectedPlots!.isEmpty) {
      return const SizedBox.shrink();
    }

    if (selectedPlots!.length == 1) {
      return _buildSinglePlotCard(context, selectedPlots!.first);
    }

    return _buildMultiPlotCard(context, selectedPlots!);
  }

  Widget _buildSinglePlotCard(BuildContext context, Plot plot) {
    final sizeSqYdVal = plot.sizeSqYd;
    final hasSizeSqYd = sizeSqYdVal != null && sizeSqYdVal > 0;
    final sizeSqYdStr =
        hasSizeSqYd ? '${Plot.formatMeasure(sizeSqYdVal)} sq yd' : '';

    final saleableSize = plot.saleableSize;
    final hasSaleableSize = saleableSize != null && saleableSize > 0;
    final priceWithPlc = plot.priceWithPlc;
    final showPlcBreakup =
        priceWithPlc != null && priceWithPlc > 0 && priceWithPlc != plot.price;
    final plc = plot.plc ? 'Yes' : 'No';
    final showPlcSummary = plot.plcApplied && plot.priceWithPlc != null;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(kIsWeb ? 24 : 20),
      decoration: _cardDecoration(),
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
                  if (hasSizeSqYd)
                    _DetailItem('Size sq yd:', sizeSqYdStr),
                  if (_hasValue(plot.plotPosition))
                    _DetailItem('Plot Position:', plot.plotPosition!),
                  if (_hasValue(plot.plotShape))
                    _DetailItem('Plot Shape:', plot.plotShape!),
                  ..._roadWidthItems(plot),
                  _DetailItem(
                    'Area:',
                    '${Plot.formatMeasure(plot.area)} sq mtr',
                  ),
                  if (hasSaleableSize)
                    _DetailItem(
                      'Saleable Size:',
                      '${Plot.formatMeasure(saleableSize)} sq yd',
                    ),
                  if (_hasValue(plot.jdaPatta))
                    _DetailItem('JDA Patta:', plot.jdaPatta!),
                  if (!hidePlotPricing && plot.effectivePrice > 0) ...[
                    _DetailItem(
                      showPlcBreakup ? 'Price (with PLC):' : 'Price:',
                      '₹${plot.effectivePrice.toStringAsFixed(2)}',
                      isHighlighted: true,
                    ),
                    if (showPlcBreakup && plot.price > 0)
                      _DetailItem(
                        'Base Price:',
                        '₹${plot.price.toStringAsFixed(2)}',
                      ),
                    if (plot.pricePerSqYdWithPlc != null &&
                        plot.pricePerSqYdWithPlc! > 0)
                      _DetailItem(
                        'Price / sq yd (with PLC):',
                        '₹${plot.pricePerSqYdWithPlc!.toStringAsFixed(2)}',
                      )
                    else if (plot.pricePerSqYd != null && plot.pricePerSqYd! > 0)
                      _DetailItem(
                        'Price / sq yd:',
                        '₹${plot.pricePerSqYd!.toStringAsFixed(2)}',
                      ),
                  ],
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
                  if (plot.status.isNotEmpty)
                    _DetailItem('Status:', plot.status),
                ]),
              ),
            ],
          ),
          if (!hidePlotPricing && showPlcSummary) ...[
            SizedBox(height: kIsWeb ? 28 : 24),
            _buildPlcSummary(plot),
          ],
        ],
      ),
    );
  }

  bool _hasValue(String? value) =>
      value != null &&
      value.trim().isNotEmpty &&
      value.trim().toLowerCase() != 'null';

  List<_DetailItem> _roadWidthItems(Plot plot) {
    return [
      if (_hasValue(plot.roadWidthFront))
        _DetailItem('Road Width Front:', _withFt(plot.roadWidthFront!)),
      if (_hasValue(plot.roadWidthBack))
        _DetailItem('Road Width Back:', _withFt(plot.roadWidthBack!)),
      if (_hasValue(plot.roadWidthLeft))
        _DetailItem('Road Width Left:', _withFt(plot.roadWidthLeft!)),
      if (_hasValue(plot.roadWidthRight))
        _DetailItem('Road Width Right:', _withFt(plot.roadWidthRight!)),
    ];
  }

  String _withFt(String value) {
    final trimmed = value.trim();
    if (trimmed.toLowerCase().endsWith('(ft)') ||
        trimmed.toLowerCase().endsWith('ft')) {
      return trimmed;
    }
    return '$trimmed (ft)';
  }

  Widget _buildMultiPlotCard(BuildContext context, List<Plot> plots) {
    final totalAmount = Plot.formatCombinedTotalAmount(plots);
    final totalStr = totalAmount.isEmpty ? '' : '₹$totalAmount';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(kIsWeb ? 24 : 20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Plot Details',
                style: TextStyle(
                  fontSize: kIsWeb ? 18 : 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.headingTextColor,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${plots.length} plots',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: kIsWeb ? 8 : 6),
          Text(
            selectedProjectName ?? '',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.darkGreyColor,
            ),
          ),
          SizedBox(height: kIsWeb ? 16 : 12),
          ...plots.asMap().entries.map((entry) {
            final idx = entry.key;
            final plot = entry.value;
            return _buildPlotRow(idx + 1, plot);
          }),
          if (!hidePlotPricing && totalStr.isNotEmpty) ...[
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Combined Total:',
                  style: TextStyle(
                    fontSize: kIsWeb ? 15 : 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.headingTextColor,
                  ),
                ),
                Text(
                  totalStr,
                  style: TextStyle(
                    fontSize: kIsWeb ? 17 : 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlotRow(int index, Plot plot) {
    final roadWidthParts = <String>[
      if (_hasValue(plot.roadWidthFront)) 'Front: ${_withFt(plot.roadWidthFront!)}',
      if (_hasValue(plot.roadWidthBack)) 'Back: ${_withFt(plot.roadWidthBack!)}',
      if (_hasValue(plot.roadWidthLeft)) 'Left: ${_withFt(plot.roadWidthLeft!)}',
      if (_hasValue(plot.roadWidthRight)) 'Right: ${_withFt(plot.roadWidthRight!)}',
    ];
    final metaParts = <String>[
      if (plot.dimensions.isNotEmpty) plot.dimensions,
      if (plot.area > 0) '${Plot.formatMeasure(plot.area)} sq mtr',
      if (plot.facing.trim().isNotEmpty) '${plot.facing} facing',
      if (_hasValue(plot.plotPosition)) 'Position: ${plot.plotPosition}',
      if (_hasValue(plot.plotShape)) 'Shape: ${plot.plotShape}',
      if (roadWidthParts.isNotEmpty) 'Road: ${roadWidthParts.join(', ')}',
      if (!hidePlotPricing && plot.effectivePrice > 0)
        '₹${plot.effectivePrice.toStringAsFixed(2)}',
      if (plot.plcApplied &&
          plot.plcPercentage != null &&
          plot.plcPercentage! > 0)
        '${plot.plcPercentage!.toStringAsFixed(2)}% PLC',
    ];
    final metaLine = metaParts.join('  |  ');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.lightGreyBorderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$index',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plot No. ${plot.plotNumber}',
                  style: TextStyle(
                    fontSize: kIsWeb ? 15 : 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.headingTextColor,
                  ),
                ),
                if (metaLine.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    metaLine,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.darkGreyColor,
                    ),
                  ),
                ],
                if (plot.saleableSize != null && plot.saleableSize! > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Saleable: ${Plot.formatMeasure(plot.saleableSize)} sq yd',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textColor,
                    ),
                  ),
                ],
                if (plot.sizeSqYd != null && plot.sizeSqYd! > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Size: ${Plot.formatMeasure(plot.sizeSqYd)} sq yd',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!hidePlotPricing && plot.effectivePrice > 0)
            Text(
              '₹${plot.effectivePrice.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: kIsWeb ? 14 : 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
            ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(kIsWeb ? 12 : 12),
      border: kIsWeb
          ? Border.all(color: const Color(0xFFE5E7EB), width: 1)
          : null,
      boxShadow: kIsWeb
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ]
          : null,
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
        color: AppColors.primaryColor.withValues(alpha: 0.02),
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
                  color: AppColors.successColor.withValues(alpha: 0.12),
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
    final val = item.value.trim();
    if (val.isEmpty || val.toLowerCase() == 'null') {
      return const SizedBox.shrink();
    }
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
              fontWeight: item.isHighlighted
                  ? FontWeight.w600
                  : FontWeight.w400,
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
