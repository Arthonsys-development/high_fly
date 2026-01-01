import 'package:flutter/material.dart';
import '../../../config/constant/app_colors.dart';
import '../../../data/models/project_model.dart' as local_model;

class ProjectSelectionDialog extends StatefulWidget {
  final List<local_model.Project> projects;
  final String? selectedProjectId;
  final Function(local_model.Project?) onProjectSelected;

  const ProjectSelectionDialog({
    super.key,
    required this.projects,
    this.selectedProjectId,
    required this.onProjectSelected,
  });

  @override
  State<ProjectSelectionDialog> createState() => _ProjectSelectionDialogState();
}

class _ProjectSelectionDialogState extends State<ProjectSelectionDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<local_model.Project> _filteredProjects = [];
  bool _isLoadingPlots = false;
  String? _loadingProjectId;

  @override
  void initState() {
    super.initState();
    _filteredProjects = widget.projects;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterProjects(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProjects = widget.projects;
      } else {
        _filteredProjects = widget.projects
            .where((project) =>
                project.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _fetchPlotsForProject(local_model.Project project) async {
    setState(() {
      _isLoadingPlots = true;
      _loadingProjectId = project.id;
    });

    try {
      // In a real implementation, you would fetch plots from the API
      // For now, we'll just simulate this with a delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Notify that the project was selected (with plots potentially loaded)
      widget.onProjectSelected(project);
      Navigator.of(context).pop();
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading plots: $e')),
      );
    } finally {
      setState(() {
        _isLoadingPlots = false;
        _loadingProjectId = null;
      });
    }
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
                        'Select Project',
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
                    onChanged: _filterProjects,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search projects...',
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
                                _filterProjects('');
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
              child: _filteredProjects.isEmpty
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
                              'No projects found',
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
                      itemCount: _filteredProjects.length,
                      itemBuilder: (context, index) {
                        final project = _filteredProjects[index];
                        final isSelected = project.id == widget.selectedProjectId;
                        
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
                              project.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                color: isSelected 
                                    ? AppColors.primaryColor 
                                    : AppColors.headingTextColor,
                              ),
                            ),
                            subtitle: Text(
                              '${project.availablePlotCount} plots available',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.darkGreyColor,
                              ),
                            ),
                            trailing: _isLoadingPlots && _loadingProjectId == project.id
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : isSelected
                                    ? const Icon(
                                        Icons.check_circle,
                                        color: AppColors.primaryColor,
                                      )
                                    : null,
                            onTap: _isLoadingPlots
                                ? null
                                : () {
                                    _fetchPlotsForProject(project);
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