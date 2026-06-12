import 'package:flutter/material.dart';
import '../../../config/constant/app_colors.dart';
import '../../../data/models/project_model.dart';

class PlotSelectionDialog extends StatefulWidget {
  final List<Plot> plots;
  final Set<String> selectedPlotIds;
  final Function(List<Plot>) onPlotsSelected;
  final int maxPlotSelect;
  final String? limitReachedMessage;

  const PlotSelectionDialog({
    super.key,
    required this.plots,
    required this.selectedPlotIds,
    required this.onPlotsSelected,
    this.maxPlotSelect = 1,
    this.limitReachedMessage,
  });

  @override
  State<PlotSelectionDialog> createState() => _PlotSelectionDialogState();
}

class _PlotSelectionDialogState extends State<PlotSelectionDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Plot> _filteredPlots = [];
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = Set<String>.from(widget.selectedPlotIds);
    _filteredPlots = widget.plots
        .where((plot) => plot.status.toLowerCase() == 'available')
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterPlots(String query) {
    setState(() {
      final availablePlots = widget.plots
          .where((plot) => plot.status.toLowerCase() == 'available')
          .toList();

      if (query.isEmpty) {
        _filteredPlots = availablePlots;
      } else {
        final normalizedQuery = query.toLowerCase();
        _filteredPlots = availablePlots.where((plot) {
          return plot.plotNumber.toLowerCase().contains(normalizedQuery) ||
              plot.remark.toLowerCase().contains(normalizedQuery);
        }).toList();
      }
    });
  }

  void _togglePlot(Plot plot) {
    if (_selectedIds.contains(plot.id)) {
      setState(() => _selectedIds.remove(plot.id));
      return;
    }

    final max = widget.maxPlotSelect < 1 ? 1 : widget.maxPlotSelect;

    if (max <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot hold any more plots'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_selectedIds.length >= max) {
      if (max == 1) {
        setState(() {
          _selectedIds
            ..clear()
            ..add(plot.id);
        });
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.limitReachedMessage ??
                'You can select up to $max plot${max > 1 ? 's' : ''} only',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _selectedIds.add(plot.id));
  }

  void _confirm() {
    final selectedPlots = widget.plots
        .where((p) => _selectedIds.contains(p.id))
        .toList();
    widget.onPlotsSelected(selectedPlots);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 520),
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
            // Header
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Select Plots',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.headingTextColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Select up to ${widget.maxPlotSelect < 1 ? 1 : widget.maxPlotSelect} plot${widget.maxPlotSelect == 1 ? '' : 's'}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.darkGreyColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_selectedIds.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_selectedIds.length}/${widget.maxPlotSelect < 1 ? 1 : widget.maxPlotSelect}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.lightGreyColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    onChanged: _filterPlots,
                    style: const TextStyle(fontSize: 15, color: Colors.black),
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

            // Plot list
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
                        final isSelected = _selectedIds.contains(plot.id);

                        return Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryColor.withValues(alpha: 0.08)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryColor
                                  : AppColors.lightGreyBorderColor,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: CheckboxListTile(
                            value: isSelected,
                            onChanged: (_) => _togglePlot(plot),
                            activeColor: AppColors.primaryColor,
                            checkColor: Colors.white,
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            title: Text(
                              'Plot No. ${plot.plotNumber}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
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
                                    fontSize: 13,
                                    color: AppColors.darkGreyColor,
                                  ),
                                ),
                                if (plot.remark.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    plot.remark,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textColor,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Done button
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppColors.lightGreyBorderColor,
                    width: 1,
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedIds.isEmpty ? null : _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primaryColor.withValues(
                      alpha: 0.4,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _selectedIds.isEmpty
                        ? 'Select at least one plot'
                        : 'Confirm ${_selectedIds.length} Plot${_selectedIds.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
