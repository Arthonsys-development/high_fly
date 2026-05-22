import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:highfly/config/constant/const_assets.dart';
import 'package:highfly/data/repository/auth_api_repository.dart';
import '../../../data/models/project_model.dart' as local_model;
import '../../../config/constant/app_colors.dart';
import '../../../config/constant/app_strings.dart';
import '../../global/widgets/custom_text_field.dart';
import 'header_icon_widget.dart';
import 'plot_details_card.dart';
import 'action_buttons.dart';
import 'project_selection_dialog.dart';
import 'plot_selection_dialog.dart';
import '../guest_alert_helper.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BookingFormSection extends StatefulWidget {
  final String title;
  final List<local_model.Project> projects;
  final VoidCallback? onPrevious;
  final Function(local_model.Project?, List<local_model.Plot>)? onNext;
  final String? nextButtonText;
  final local_model.Project? initialProject;
  final List<local_model.Plot>? initialPlots;
  final VoidCallback? onRefreshProjects;
  final bool isRefreshingProjects;

  const BookingFormSection({
    super.key,
    required this.title,
    required this.projects,
    this.onPrevious,
    this.onNext,
    this.nextButtonText,
    this.initialProject,
    this.initialPlots,
    this.onRefreshProjects,
    this.isRefreshingProjects = false,
  });

  @override
  State<BookingFormSection> createState() => _BookingFormSectionState();
}

class _BookingFormSectionState extends State<BookingFormSection> {
  local_model.Project? _selectedProject;
  List<local_model.Plot> _selectedPlots = [];
  final TextEditingController _projectController = TextEditingController();
  final TextEditingController _plotController = TextEditingController();
  List<local_model.Plot> _availablePlots = [];
  bool _isLoadingPlots = false;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    if (widget.initialProject != null) {
      _selectedProject = widget.initialProject;
      _projectController.text = widget.initialProject!.name;
      _fetchPlotsForProject(
        widget.initialProject!,
        preserveExistingSelection: true,
      );
    }
    if (widget.initialPlots != null && widget.initialPlots!.isNotEmpty) {
      _selectedPlots = List.from(widget.initialPlots!);
      _plotController.text = _buildPlotDisplayText(_selectedPlots);
    }
  }

  @override
  void dispose() {
    _projectController.dispose();
    _plotController.dispose();
    super.dispose();
  }

  String _buildPlotDisplayText(List<local_model.Plot> plots) {
    if (plots.isEmpty) return '';
    if (plots.length == 1) return plots.first.displayText;
    return '${plots.length} plots selected (${plots.map((p) => p.plotNumber).join(', ')})';
  }

  Future<void> _fetchPlotsForProject(
    local_model.Project project, {
    bool preserveExistingSelection = false,
  }) async {
    final previousPlots = preserveExistingSelection
        ? List<local_model.Plot>.from(_selectedPlots.isNotEmpty
            ? _selectedPlots
            : widget.initialPlots ?? [])
        : <local_model.Plot>[];

    setState(() {
      _isLoadingPlots = true;
      _availablePlots = [];
      if (!preserveExistingSelection) {
        _selectedPlots = [];
        _plotController.clear();
      }
    });

    try {
      final apiRepository = AuthApiRepository();
      final result = await apiRepository.getPlotsByProjectId(project.id);

      if (result['success']) {
        final apiPlots = result['data'] as List<Plot>;
        final localPlots = apiPlots.map((plot) => plot.toLocalModel()).toList();

        List<local_model.Plot> plotsToSelect = [];
        if (previousPlots.isNotEmpty) {
          for (final prev in previousPlots) {
            try {
              plotsToSelect.add(localPlots.firstWhere((p) => p.id == prev.id));
            } catch (_) {
              plotsToSelect.add(prev);
            }
          }
        }

        setState(() {
          _availablePlots = localPlots;
          _isLoadingPlots = false;
          if (plotsToSelect.isNotEmpty) {
            _selectedPlots = plotsToSelect;
            _plotController.text = _buildPlotDisplayText(_selectedPlots);
          }
        });
      } else {
        setState(() => _isLoadingPlots = false);
        debugPrint('Error loading plots: ${result['message']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading plots: ${result['message']}')),
        );
      }
    } catch (e) {
      setState(() => _isLoadingPlots = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading plots: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = kIsWeb ? 32.0 : 24.0;
    final largeSpacing = kIsWeb ? 48.0 : 40.0;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: kIsWeb ? 24 : 20,
        bottom: kIsWeb ? 24 : 20,
      ),
      child: Column(
        children: [
          SizedBox(height: kIsWeb ? 24 : 20),

          HeaderIconWidget(
            icon: IconsAssets.projectIcon,
            title: 'Select Project & Plots',
            subtitle: 'Choose a project, then select one or more plots',
          ),

          if (widget.onRefreshProjects != null) ...[
            SizedBox(height: kIsWeb ? 16 : 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: widget.isRefreshingProjects
                    ? null
                    : widget.onRefreshProjects,
                icon: widget.isRefreshingProjects
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(
                        Icons.refresh,
                        size: 18,
                        color: AppColors.primaryColor,
                      ),
                label: Text(
                  widget.isRefreshingProjects ? 'Refreshing...' : 'Refresh Projects',
                  style: TextStyle(
                    fontSize: kIsWeb ? 15 : 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryColor,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryColor,
                  padding: EdgeInsets.symmetric(
                    horizontal: kIsWeb ? 16 : 12,
                    vertical: kIsWeb ? 10 : 8,
                  ),
                ),
              ),
            ),
          ],

          SizedBox(height: largeSpacing),

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

          SizedBox(height: spacing),

          // Plot selection field
          if (_selectedProject != null) ...[
            GestureDetector(
              onTap: _availablePlots.isEmpty && !_isLoadingPlots
                  ? null
                  : _showPlotSelectionDialog,
              child: CustomTextField(
                titleText: 'Available Plots',
                controller: _plotController,
                hintText: _isLoadingPlots
                    ? 'Loading plots...'
                    : _availablePlots.isEmpty
                        ? 'No plots available'
                        : 'Select Plots (multiple allowed)',
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
            SizedBox(height: kIsWeb ? 36 : 32),
          ],

          if (_selectedProject == null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primaryColor.withValues(alpha: 0.3),
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
            SizedBox(height: kIsWeb ? 36 : 32),
          ],

          // Plot details card — shows all selected plots
          PlotDetailsCard(
            selectedPlots: _selectedPlots.isEmpty ? null : _selectedPlots,
            selectedProjectName: _selectedProject?.name,
          ),

          SizedBox(height: largeSpacing),

          ActionButtons(
            onPrevious: widget.onPrevious,
            onNext: _canProceed() ? _handleNext : null,
            isPreviousEnabled: widget.onPrevious != null,
            isNextEnabled: _canProceed(),
            nextButtonText: widget.nextButtonText,
          ),

          SizedBox(height: kIsWeb ? 24 : 20),
        ],
      ),
    );
  }

  bool _canProceed() {
    if (_selectedProject == null) return false;
    return _selectedPlots.isNotEmpty;
  }

  Future<void> _handleNext() async {
    final isGuest = await _secureStorage.read(key: SharedPreferenceStrings.isGuest);
    if (isGuest == 'true') {
      if (mounted) {
        GuestAlertHelper.showGuestAlert(
          context,
          message:
              'Guest users cannot book or hold plots. Please sign in with your phone number to access all features.',
        );
      }
      return;
    }
    widget.onNext?.call(_selectedProject, _selectedPlots);
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
            _selectedPlots = [];
            _projectController.text = project?.name ?? '';
            _plotController.clear();
          });
          if (project != null) {
            _fetchPlotsForProject(project);
          }
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
        selectedPlotIds: _selectedPlots.map((p) => p.id).toSet(),
        onPlotsSelected: (plots) {
          setState(() {
            _selectedPlots = plots;
            _plotController.text = _buildPlotDisplayText(plots);
          });
        },
      ),
    );
  }
}
