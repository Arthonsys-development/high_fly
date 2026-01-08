import 'package:flutter/material.dart';
import '../../../config/constant/app_colors.dart';
import '../../../data/models/project_model.dart';

class PlotSelectionDialog extends StatefulWidget {
  final List<Plot> plots;
  final String? selectedPlotId;
  final Function(Plot?) onPlotSelected;

  const PlotSelectionDialog({
    super.key,
    required this.plots,
    this.selectedPlotId,
    required this.onPlotSelected,
  });

  @override
  State<PlotSelectionDialog> createState() => _PlotSelectionDialogState();
}

class _PlotSelectionDialogState extends State<PlotSelectionDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Plot> _filteredPlots = [];

  @override
  void initState() {
    super.initState();
    // Filter to show only "Available" status plots
    _filteredPlots = widget.plots.where((plot) => 
      plot.status.toLowerCase() == 'available'
    ).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterPlots(String query) {
    setState(() {
      // Always filter to show only "Available" status plots first
      final availablePlots = widget.plots.where((plot) => 
        plot.status.toLowerCase() == 'available'
      ).toList();
      
      if (query.isEmpty) {
        _filteredPlots = availablePlots;
      } else {
        final normalizedQuery = query.toLowerCase();
        _filteredPlots = availablePlots.where((plot) {
          final remarkText = plot.remark.toLowerCase();
          return plot.plotNumber.toLowerCase().contains(normalizedQuery) ||
              remarkText.contains(normalizedQuery);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 400),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.lightGreyBorderColor,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text(
                        'Select Plot',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.headingTextColor,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.lightGreyColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    onChanged: _filterPlots,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search plots...',
                      hintStyle: const TextStyle(
                        fontSize: 15,
                        color: AppColors.lightGreyColor,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.lightGreyColor,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                _filterPlots('');
                              },
                              icon: const Icon(
                                Icons.clear,
                                color: AppColors.lightGreyColor,
                              ),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppColors.lightGreyBorderColor,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppColors.lightGreyBorderColor,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppColors.primaryColor,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: _filteredPlots.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 48,
                              color: AppColors.lightGreyColor,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No plots found',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.darkGreyColor,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Try adjusting your search terms',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.lightGreyColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredPlots.length,
                      itemBuilder: (context, index) {
                        final plot = _filteredPlots[index];
                        final isSelected = plot.id == widget.selectedPlotId;
                        
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? AppColors.primaryColor.withValues(alpha: 0.1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected 
                                  ? AppColors.primaryColor 
                                  : AppColors.lightGreyBorderColor,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            title: Text(
                              "Plot No. ${plot.plotNumber}",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                color: isSelected 
                                    ? AppColors.primaryColor 
                                    : AppColors.headingTextColor,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  plot.displayTextOnPopup,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.darkGreyColor,
                                  ),
                                ),
                                if (plot.remark.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    plot.remark,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textColor,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            trailing: isSelected
                                ? const Icon(
                                    Icons.check_circle,
                                    color: AppColors.primaryColor,
                                  )
                                : null,
                            onTap: () {
                              widget.onPlotSelected(plot);
                              Navigator.of(context).pop();
                            },
                          ),
                        );
                      },
                    ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}