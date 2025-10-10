import 'package:flutter/material.dart';
import 'package:highfly/config/constant/const_assets.dart';
import '../../../data/models/project_model.dart';
import '../../../config/constant/app_colors.dart';
import '../../global/widgets/custom_text_field.dart';
import 'header_icon_widget.dart';
import 'plot_details_card.dart';
import 'action_buttons.dart';
import 'project_selection_dialog.dart';
import 'plot_selection_dialog.dart';

class BookingFormSection extends StatefulWidget {
  final String title;
  final List<Project> projects;
  final VoidCallback? onPrevious;
  final Function(Project?, Plot?)? onNext;
  final String? nextButtonText;

  const BookingFormSection({
    super.key,
    required this.title,
    required this.projects,
    this.onPrevious,
    this.onNext,
    this.nextButtonText,
  });

  @override
  State<BookingFormSection> createState() => _BookingFormSectionState();
}

class _BookingFormSectionState extends State<BookingFormSection> {
  Project? _selectedProject;
  Plot? _selectedPlot;
  final TextEditingController _projectController = TextEditingController();
  final TextEditingController _plotController = TextEditingController();

  @override
  void dispose() {
    _projectController.dispose();
    _plotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 20, bottom: 20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          
          // Header with icon
          HeaderIconWidget(
            icon: IconsAssets.projectIcon,
            title: 'Select Project & Plot',
            subtitle: 'Choose a project, then select a plot',
          ),
          
          const SizedBox(height: 40),
          
          // Project selection field
          GestureDetector(
            onTap: _showProjectSelectionDialog,
            child: CustomTextField(
              titleText: 'Project',
              controller: _projectController,
              hintText: 'Select Project',
              isMandatory: true,
              borderRadius: 6,
              enabled: false,
              suffixIcon: const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.lightGreyColor,
                size: 20,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Plot selection field - only visible after project selection
          if (_selectedProject != null) ...[
            GestureDetector(
              onTap: _showPlotSelectionDialog,
              child: CustomTextField(
                titleText: 'Available Plot',
                controller: _plotController,
                hintText: 'Select Plot',
                isMandatory: true,
                borderRadius: 6,
                enabled: false,
                suffixIcon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.lightGreyColor,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
          
          // Helper message when no project is selected
          if (_selectedProject == null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primaryColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Please select a project first to view available plots',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
          
          // Plot details card
          PlotDetailsCard(
            selectedPlot: _selectedPlot,
            selectedProjectName: _selectedProject?.name,
          ),
          
          const SizedBox(height: 40),
          
          // Action buttons
          ActionButtons(
            onPrevious: widget.onPrevious,
            onNext: _canProceed() ? () => widget.onNext?.call(_selectedProject, _selectedPlot) : null,
            isPreviousEnabled: widget.onPrevious != null,
            isNextEnabled: _canProceed(),
            nextButtonText: widget.nextButtonText,
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  bool _canProceed() {
    // Can proceed only if project is selected and plot is selected (when plot field is visible)
    if (_selectedProject == null) return false;
    return _selectedPlot != null;
  }

  void _showProjectSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => ProjectSelectionDialog(
        projects: widget.projects,
        selectedProjectId: _selectedProject?.id,
        onProjectSelected: (project) {
          setState(() {
            _selectedProject = project;
            _selectedPlot = null; // Reset plot selection when project changes
            _projectController.text = project?.name ?? '';
            _plotController.clear(); // Clear plot field when project changes
          });
        },
      ),
    );
  }

  void _showPlotSelectionDialog() {
    if (_selectedProject == null) return;
    
    showDialog(
      context: context,
      builder: (context) => PlotSelectionDialog(
        plots: _selectedProject!.plots,
        selectedPlotId: _selectedPlot?.id,
        onPlotSelected: (plot) {
          setState(() {
            _selectedPlot = plot;
            _plotController.text = plot?.displayText ?? '';
          });
        },
      ),
    );
  }
}
