import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:highfly/config/constant/const_assets.dart';
import 'package:highfly/module/providers/app_config_provider.dart';
import 'package:highfly/data/models/app_config_model.dart';
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

class BookingFormSection extends ConsumerStatefulWidget {
  final String title;
  final List<local_model.Project> projects;
  final VoidCallback? onPrevious;
  final Function(local_model.Project?, List<local_model.Plot>)? onNext;
  final String? nextButtonText;
  final local_model.Project? initialProject;
  final List<local_model.Plot>? initialPlots;
  final VoidCallback? onRefreshProjects;
  final bool isRefreshingProjects;
  final bool isHoldFlow;

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
    this.isHoldFlow = false,
  });

  @override
  ConsumerState<BookingFormSection> createState() => _BookingFormSectionState();
}

class _BookingFormSectionState extends ConsumerState<BookingFormSection> {
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
    if (widget.isHoldFlow) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _trimPlotsToHoldLimit());
    }
  }

  void _trimPlotsToHoldLimit() {
    if (!widget.isHoldFlow || !mounted) return;
    final max = _getMaxPlotSelect();
    if (_selectedPlots.length <= max) return;
    setState(() {
      _selectedPlots = max > 0 ? _selectedPlots.sublist(0, max) : [];
      _plotController.text = _buildPlotDisplayText(_selectedPlots);
    });
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
    ref.watch(appConfigControllerProvider);
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
                hintText: _plotFieldHintText(),
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

          if (widget.isHoldFlow && _selectedProject != null) ...[
            _buildHoldCapacityBanner(),
            SizedBox(height: spacing),
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

    if (widget.isHoldFlow) {
      final max = _getMaxPlotSelect();
      if (max <= 0) {
        if (mounted) _showHoldLimitReachedDialog();
        return;
      }
      if (_selectedPlots.length > max) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'You can hold at most $max plot${max == 1 ? '' : 's'} '
                '(${_appConfig?.currentHoldBookings ?? 0}/${_appConfig?.maxHoldsPerAgent ?? 0} active holds)',
              ),
            ),
          );
        }
        _trimPlotsToHoldLimit();
        return;
      }
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

  AppConfigData? get _appConfig =>
      ref.read(appConfigControllerProvider).config?.config;

  int _getMaxPlotSelect() {
    final config = _appConfig;
    if (widget.isHoldFlow) {
      return config?.maxPlotsForHoldSelection ?? 1;
    }
    final max = config?.maxPlotSelect ?? 1;
    return max < 1 ? 1 : max;
  }

  String _plotFieldHintText() {
    if (_isLoadingPlots) return 'Loading plots...';
    if (_availablePlots.isEmpty) return 'No plots available';
    if (widget.isHoldFlow) {
      final max = _getMaxPlotSelect();
      if (max <= 0) return 'Hold limit reached';
      if (max == 1) return 'Select 1 plot to hold';
      return 'Select up to $max plots to hold';
    }
    final max = _getMaxPlotSelect();
    if (max == 1) return 'Select a plot';
    return 'Select up to $max plots';
  }

  Widget _buildHoldCapacityBanner() {
    final config = _appConfig;
    final current = config?.currentHoldBookings ?? 0;
    final maxHolds = config?.maxHoldsPerAgent ?? 1;
    final remaining = config?.remainingHoldSlots ?? 0;
    final maxSelectable = _getMaxPlotSelect();

    final Color bannerColor;
    final IconData icon;
    String message;

    if (remaining <= 0) {
      bannerColor = Colors.red;
      icon = Icons.block;
      message =
          'You have reached the maximum of $maxHolds active hold${maxHolds == 1 ? '' : 's'} ($current/$maxHolds). '
          'Complete or release existing holds before holding more plots.';
    } else {
      bannerColor = AppColors.primaryColor;
      icon = Icons.info_outline;
      message =
          'Active holds: $current/$maxHolds. You can hold up to $maxSelectable more plot${maxSelectable == 1 ? '' : 's'} in this session.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: bannerColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: bannerColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: bannerColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHoldLimitReachedDialog() {
    final config = _appConfig;
    final maxHolds = config?.maxHoldsPerAgent ?? 1;
    final current = config?.currentHoldBookings ?? 0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.block, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text('Hold Limit Reached'),
          ],
        ),
        content: Text(
          'You already have $current active hold${current == 1 ? '' : 's'} '
          'and the maximum allowed is $maxHolds per agent.\n\n'
          'Complete or release existing holds before holding more plots.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPlotSelectionDialog() {
    if (_selectedProject == null || _availablePlots.isEmpty) return;

    final maxPlotSelect = _getMaxPlotSelect();

    if (widget.isHoldFlow && maxPlotSelect <= 0) {
      _showHoldLimitReachedDialog();
      return;
    }

    final config = _appConfig;
    final holdLimitMessage = widget.isHoldFlow && config != null
        ? 'You can hold up to $maxPlotSelect plot${maxPlotSelect == 1 ? '' : 's'} '
            '(${config.currentHoldBookings}/${config.maxHoldsPerAgent} active holds used)'
        : null;

    showDialog(
      context: context,
      builder: (context) => PlotSelectionDialog(
        plots: _availablePlots,
        selectedPlotIds: _selectedPlots.map((p) => p.id).toSet(),
        maxPlotSelect: maxPlotSelect,
        limitReachedMessage: holdLimitMessage,
        onPlotsSelected: (plots) {
          final trimmed = plots.length > maxPlotSelect
              ? plots.sublist(0, maxPlotSelect)
              : plots;
          setState(() {
            _selectedPlots = trimmed;
            _plotController.text = _buildPlotDisplayText(trimmed);
          });
        },
      ),
    );
  }
}
