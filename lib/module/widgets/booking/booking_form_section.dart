import 'package:flutter/material.dart';
import 'package:highfly/config/constant/const_assets.dart';
import 'package:highfly/data/repository/auth_api_repository.dart';
import '../../../data/models/project_model.dart' as local_model;
import '../../../config/constant/app_colors.dart';
import '../../global/widgets/custom_text_field.dart';
import 'header_icon_widget.dart';
import 'plot_details_card.dart';
import 'action_buttons.dart';
import 'project_selection_dialog.dart';
import 'plot_selection_dialog.dart';

class BookingFormSection extends StatefulWidget {
  final String title;
  final List<local_model.Project> projects;
  final VoidCallback? onPrevious;
  final Function(local_model.Project?, local_model.Plot?)? onNext;
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
  local_model.Project? _selectedProject;
  local_model.Plot? _selectedPlot;
  final TextEditingController _projectController = TextEditingController();
  final TextEditingController _plotController = TextEditingController();
  List<local_model.Plot> _availablePlots = [];
  bool _isLoadingPlots = false;

  @override
  void dispose() {
    _projectController.dispose();
    _plotController.dispose();
    super.dispose();
  }

  Future<void> _fetchPlotsForProject(local_model.Project project) async {
    setState(() {
      _isLoadingPlots = true;
      _availablePlots = [];
      _selectedPlot = null;
      _plotController.clear();
    });

    try {
      final apiRepository = AuthApiRepository();
      final result = await apiRepository.getPlotsByProjectId(project.id);
      
      if (result['success']) {
        // Convert API Plot models to local Plot models
        final apiPlots = result['data'] as List<Plot>;
        final localPlots = apiPlots.map((plot) => plot.toLocalModel()).toList();
        
        setState(() {
          _availablePlots = localPlots;
          _isLoadingPlots = false;
        });
      } else {
        setState(() {
          _isLoadingPlots = false;
        });
        print("Error loading plots: ${result['message']}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading plots: ${result['message']}')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingPlots = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading plots: $e')),
      );
    }
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
              onTap: _availablePlots.isEmpty && !_isLoadingPlots
                  ? null
                  : _showPlotSelectionDialog,
              child: CustomTextField(
                titleText: 'Available Plot',
                controller: _plotController,
                hintText: _isLoadingPlots
                    ? 'Loading plots...'
                    : _availablePlots.isEmpty
                        ? 'No plots available'
                        : 'Select Plot',
                isMandatory: true,
                borderRadius: 6,
                enabled: false,
                suffixIcon: _isLoadingPlots
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(
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
            
            // Fetch plots for the selected project
            if (project != null) {
              _fetchPlotsForProject(project);
            }
          });
        },
      ),
    );
  }

  void _showPlotSelectionDialog() {
    if (_selectedProject == null || _availablePlots.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => PlotSelectionDialog(
        plots: _availablePlots,
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