import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:highfly/data/repository/auth_api_repository.dart';
import 'package:highfly/data/models/response_model/project_response_model.dart';

// Projects State
class ProjectsState {
  final bool isLoading;
  final List<Project> projects;
  final List<Project> activeProjects;
  final String? error;

  ProjectsState({
    this.isLoading = false,
    this.projects = const [],
    this.activeProjects = const [],
    this.error,
  });

  ProjectsState copyWith({
    bool? isLoading,
    List<Project>? projects,
    List<Project>? activeProjects,
    String? error,
  }) {
    return ProjectsState(
      isLoading: isLoading ?? this.isLoading,
      projects: projects ?? this.projects,
      activeProjects: activeProjects ?? this.activeProjects,
      error: error,
    );
  }
}

// Projects Controller
class ProjectsController extends Notifier<ProjectsState> {
  late AuthApiRepository _authApiRepository;
  bool _isDisposed = false;

  @override
  ProjectsState build() {
    _authApiRepository = AuthApiRepository();
    // Load projects when the provider is initialized
    print('ProjectsController: Initializing and loading projects...');
    loadProjects();
    loadActiveProjects();
    return ProjectsState();
  }

  // Load all projects from API
  Future<void> loadProjects() async {
    if (_isDisposed) return;
    print('ProjectsController: Loading all projects...');
    // Don't return early if already loading, but show that we're refreshing
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _authApiRepository.getProjects();
      if (_isDisposed) return;
      print('ProjectsController: Projects API result success: ${result['success']}');
      print('ProjectsController: Projects API result data length: ${result['data']?.length ?? 0}');
      
      if (result['success']) {
        final projects = result['data'] as List<Project>;
        print('ProjectsController: Successfully loaded ${projects.length} projects');
        print('ProjectsController: First project name: ${projects.isNotEmpty ? projects[0].name : "No projects"}');
        state = state.copyWith(
          isLoading: false,
          projects: projects,
          error: null,
        );
        print('ProjectsController: State updated with ${projects.length} projects');
      } else {
        if (_isDisposed) return;
        final errorMessage = result['message'] as String? ?? 'Failed to load projects';
        print('ProjectsController: Failed to load projects: $errorMessage');
        state = state.copyWith(
          isLoading: false,
          error: errorMessage,
        );
      }
    } catch (e, stackTrace) {
      if (_isDisposed) return;
      print('ProjectsController: Exception while loading projects: $e');
      print('ProjectsController: Stack trace: $stackTrace');
      state = state.copyWith(
        isLoading: false,
        error: 'Error loading projects: ${e.toString()}',
      );
    }
  }

  // Load active projects from API (for counting only)
  Future<void> loadActiveProjects() async {
    if (_isDisposed) return;
    print('ProjectsController: Loading active projects for counting...');
    // Don't set isLoading to true here since we're loading in parallel with all projects
    // We just want to update the activeProjects count

    try {
      final result = await _authApiRepository.getActiveProjects();
      if (_isDisposed) return;
      print('ProjectsController: Active projects API result success: ${result['success']}');
      print('ProjectsController: Active projects API result data length: ${result['data']?.length ?? 0}');
      
      if (result['success']) {
        final activeProjects = result['data'] as List<Project>;
        print('ProjectsController: Successfully loaded ${activeProjects.length} active projects for counting');
        if (!_isDisposed) {
          state = state.copyWith(
            activeProjects: activeProjects,
          );
        }
      } else {
        final errorMessage = result['message'] as String? ?? 'Failed to load active projects';
        print('ProjectsController: Failed to load active projects: $errorMessage');
        // Don't set error here as it's just for counting
      }
    } catch (e, stackTrace) {
      if (_isDisposed) return;
      print('ProjectsController: Exception while loading active projects: $e');
      print('ProjectsController: Stack trace: $stackTrace');
      // Don't set error here as it's just for counting
    }
  }

  void dispose() {
    _isDisposed = true;
    // super.dispose();
  }
}

// Projects Controller Provider
final projectsControllerProvider = NotifierProvider<ProjectsController, ProjectsState>(() {
  return ProjectsController();
});