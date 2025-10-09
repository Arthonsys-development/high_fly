import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:highfly/config/constant/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:highfly/module/providers/projects_provider.dart';
import 'package:highfly/module/providers/user_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:highfly/config/routes.dart';
import 'package:highfly/data/models/response_model/project_response_model.dart';

import '../../utils/responsive.dart';
import '../../widgets/dashboard_side_menu.dart';
import '../Booking/BookingScreen.dart';
import '../visitors/visitors_screen.dart';
import '../../widgets/add_visit_dialog.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with WidgetsBindingObserver {
  int selectedMenuIndex = 2;
  bool sideMenuVisible = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isDisposed = false;

  void onMenuItemSelected(int index) {
    if (_isDisposed) return;
    setState(() {
      selectedMenuIndex = index;
    });
  }

  void toggleSideMenu() {
    if (_isDisposed) return;
    setState(() {
      sideMenuVisible = !sideMenuVisible;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Load projects and user profile when dashboard is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed) {
        ref.read(projectsControllerProvider.notifier).loadProjects();
      }
    });
    
    // Add listener to search controller
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) return;
    // Handle app lifecycle changes to prevent rendering issues
    if (state == AppLifecycleState.paused) {
      // App is in background, pause any heavy operations
    } else if (state == AppLifecycleState.resumed) {
      // App is back in foreground, refresh data if needed
      if (!_isDisposed) {
        ref.read(projectsControllerProvider.notifier).loadProjects();
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_isDisposed) return;
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  List<Project> _filterProjects(List<Project> projects, String query) {
    if (query.isEmpty) {
      return projects;
    }
    
    return projects.where((project) {
      return project.name.toLowerCase().contains(query) ||
             project.location.toLowerCase().contains(query) ||
             project.description.toLowerCase().contains(query) ||
             project.status.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: AppColors.textFieldBGColor,
      drawer: isMobile
          ? MobileSideMenuDrawer(
              selectedIndex: selectedMenuIndex,
              onMenuItemSelected: onMenuItemSelected,
            )
          : null,
      body: SafeArea(
        child: Row(
          children: [
            // Side Menu for tablet and desktop
            if (!isMobile)
              DashboardSideMenu(
                selectedIndex: selectedMenuIndex,
                onMenuItemSelected: onMenuItemSelected,
                isVisible: sideMenuVisible,
              ),

            // Main Content
            Expanded(
              child: Column(
                children: [
                  // Top App Bar
                  if (isMobile || !sideMenuVisible) _buildTopAppBar(),

                  // Main Content Area
                  Expanded(
                    child: _buildMainContent(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAppBar() {
    final isMobile = Responsive.isMobile(context);

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (isMobile)
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.list, color: Colors.orange),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            )
          else
            IconButton(
              icon: Icon(
                sideMenuVisible ? Icons.menu_open : Icons.menu,
                color: AppColors.primaryTextColor,
              ),
              onPressed: toggleSideMenu,
            ),

          const SizedBox(width: 12),
          Text(
            _getPageTitle(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryTextColor,
            ),
          ),
          // const Spacer(),
          // Sign out button
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.orange),
            onPressed: () async {
              // Sign out from Firebase
              await FirebaseAuth.instance.signOut();
              // Clear access token from secure storage
              const secureStorage = FlutterSecureStorage();
              secureStorage.deleteAll();
              // await secureStorage.delete(key: 'access_token');
              // Navigate back to sign in screen
              if (mounted) {
                context.go(Routes.signIn);
              }
            },
          ),
        ],
      ),
    );
  }

  String _getPageTitle() {
    switch (selectedMenuIndex) {
      case 0:
        return 'HighFly - Projects';
      case 1:
        return 'HighFly - Visits';
      case 2:
        return 'HighFly - Booking';
      default:
        return 'HighFly Dashboard';
    }
  }

  Widget _buildMainContent() {
    // Return different content based on selected menu item
    switch (selectedMenuIndex) {
      case 0:
        return _buildProjectContent();
      case 1:
        return _buildVisitorContent();
      case 2:
        return _buildBookingProcessorContent();
      default:
        return _buildProjectContent();
    }
  }

  Widget _buildProjectContent() {
    return Responsive(
      mobile: _buildMobileLayout(),
      tablet: _buildTabletDesktopLayout(),
      desktop: _buildTabletDesktopLayout(),
    );
  }

  Widget _buildVisitorContent() {
    return const VisitorsScreen();
  }

  Widget _buildBookingProcessorContent() {
    return BookingProcessorScreen();
  }

  Widget _buildMobileLayout() {
    final projectsState = ref.watch(projectsControllerProvider);
    final filteredProjects = _filterProjects(projectsState.projects, _searchQuery);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and Refresh Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Projects",
                style: TextStyle(
                  color: AppColors.primaryTextColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              // IconButton(
              //   icon: const Icon(Icons.refresh, color: Colors.orange),
              //   onPressed: () {
              //     ref.read(projectsControllerProvider.notifier).loadProjects();
              //     ref.read(projectsControllerProvider.notifier).loadActiveProjects();
              //   },
              // ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              _statsCard(
                context,
                title: "Total Projects",
                count: projectsState.projects.length.toString(),
                // subtitleLeft: "Planning: 0",
                // subtitleRight: "Completed: 0",
                icon: Icons.insert_chart_outlined,
                color: Colors.orange,
              ),
              _statsCard(
                context,
                title: "Active Projects",
                count: projectsState.activeProjects.length.toString(),
                icon: Icons.show_chart,
                color: Colors.green,
              ),
            ],
          ),
          // Stats Cards - Stacked vertically on mobile


          const SizedBox(height: 20),

          // Mobile Projects List
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar - Full width on mobile
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: TextField(
                    controller: _searchController,
                    cursorColor: AppColors.primaryTextColor,
                    style: const TextStyle(fontSize: 14, color: AppColors.primaryTextColor),
                    decoration: InputDecoration(
                      hintText: "Search projects...",
                      prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.primaryTextColor,),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppColors.secondaryTextColor, // Normal border color
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppColors.secondaryTextColor, // Border color when focused
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ),

                // Show loading indicator
                if (projectsState.isLoading)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 8),
                          Text('Loading projects...'),
                        ],
                      ),
                    ),
                  ),

                // Show error message if any
                if (projectsState.error != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          'Error loading projects:',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          projectsState.error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            ref.read(projectsControllerProvider.notifier).loadProjects();
                            ref.read(projectsControllerProvider.notifier).loadActiveProjects();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),

                // Show empty state if no projects and no errors
                if (!projectsState.isLoading && 
                    projectsState.error == null && 
                    filteredProjects.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No projects found',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                          // SizedBox(height: 8),
                          // Text(
                          //   'Try a different search term',
                          //   style: TextStyle(
                          //     color: Colors.grey,
                          //     fontSize: 14,
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                  ),

                // Mobile Project Cards instead of DataTable (show FILTERED projects)
                if (!projectsState.isLoading && projectsState.error == null)
                  ...filteredProjects.map((project) => _buildMobileProjectCard(project)).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletDesktopLayout() {
    final isTablet = Responsive.isTablet(context);
    final isDesktop = Responsive.isDesktop(context);
    final projectsState = ref.watch(projectsControllerProvider);
    final filteredProjects = _filterProjects(projectsState.projects, _searchQuery);

    return SingleChildScrollView(
      padding: EdgeInsets.all(isTablet ? 12.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and Refresh Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  "Projects",
                  style: TextStyle(
                    color: AppColors.primaryTextColor,
                    fontSize: isTablet ? 22 : 25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.orange),
                onPressed: () {
                  ref.read(projectsControllerProvider.notifier).loadProjects();
                  ref.read(projectsControllerProvider.notifier).loadActiveProjects();
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Stats Cards - Responsive grid
          isTablet
              ? Column(
                  children: [
                    _statsCard(
                      context,
                      title: "Total Projects",
                      count: projectsState.projects.length.toString(),
                      subtitleLeft: "Planning: 0",
                      subtitleRight: "Completed: 0",
                      icon: Icons.insert_chart_outlined,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    _statsCard(
                      context,
                      title: "Active Projects",
                      count: projectsState.activeProjects.length.toString(),
                      icon: Icons.show_chart,
                      color: Colors.green,
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _statsCard(
                        context,
                        title: "Total Projects",
                        count: projectsState.projects.length.toString(),
                        subtitleLeft: "Planning: 0",
                        subtitleRight: "Completed: 0",
                        icon: Icons.insert_chart_outlined,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _statsCard(
                        context,
                        title: "Active Projects",
                        count: projectsState.activeProjects.length.toString(),
                        icon: Icons.show_chart,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),

          const SizedBox(height: 20),

          // Projects Table/List Container
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar - Responsive width
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: SizedBox(
                    height: 40,
                    width: isTablet
                        ? double.infinity
                        : MediaQuery.of(context).size.width / 3,
                    child: TextField(
                      controller: _searchController,
                      cursorColor: AppColors.primaryTextColor,
                      style: const TextStyle(fontSize: 14, color: AppColors.primaryTextColor),
                      decoration: InputDecoration(
                        hintText: "Search projects...",
                        prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.primaryTextColor,),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppColors.secondaryTextColor, // Normal border color
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppColors.secondaryTextColor, // Border color when focused
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Show loading indicator
                if (projectsState.isLoading)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 8),
                          Text('Loading projects...'),
                        ],
                      ),
                    ),
                  ),

                // Show error message if any
                if (projectsState.error != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          'Error loading projects:',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          projectsState.error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            ref.read(projectsControllerProvider.notifier).loadProjects();
                            ref.read(projectsControllerProvider.notifier).loadActiveProjects();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),

                // Show empty state if no projects and no errors
                if (!projectsState.isLoading && 
                    projectsState.error == null && 
                    filteredProjects.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No projects found',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                          // SizedBox(height: 8),
                          // Text(
                          //   'Try a different search term',
                          //   style: TextStyle(
                          //     color: Colors.grey,
                          //     fontSize: 14,
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                  ),

                // Projects Data - Responsive table (show FILTERED projects)
                if (!projectsState.isLoading && 
                    projectsState.error == null && 
                    filteredProjects.isNotEmpty)
                  isTablet
                      ? _buildTabletProjectsList(filteredProjects)
                      : _buildDesktopProjectsTable(filteredProjects),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color),
    );
  }

  Widget _statsCard(BuildContext context,
      {required String title,
        required String count,
        String? subtitleLeft,
        String? subtitleRight,
        required IconData icon,
        required Color color}) {
    final isTablet = Responsive.isTablet(context);
    final isMobile = Responsive.isMobile(context);
    
    return Expanded(
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: AppColors.primaryTextColor,
                            fontSize: isMobile ? 14 : 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          count,
                          style: TextStyle(
                            color: AppColors.primaryTextColor,
                            fontSize: isMobile ? 20 : 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(isMobile ? 8 : 12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: isMobile ? 20 : 28,
                    ),
                  )
                ],
              ),
              const SizedBox(height: 10),
              if (subtitleLeft != null && subtitleRight != null)
                isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subtitleLeft,
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitleRight,
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            subtitleLeft,
                            style: const TextStyle(color: Colors.grey),
                          ),
                          Text(
                            subtitleRight,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dropdownField(String hint) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      hint: Text(hint),
      items: const [],
      onChanged: (_) {},
    );
  }

  Widget _statusChip(String text) {
    return Icon(Icons.circle, size: 15, color: text == 'active' ? Colors.green : Colors.red);

    //   Chip(
    //   label: Text(text, style: const TextStyle(color: AppColors.primaryTextColor),),
    //   backgroundColor: Colors.green,
    // );
  }

  // Mobile Project Card Widget
  Widget _buildMobileProjectCard(Project project) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadiusGeometry.all(Radius.circular(5)),
            child: Image.network(
            project.projectPhoto, // sample image url
            width: MediaQuery.of(context).size.width,
            height: 150,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child; // Image loaded
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                      (loadingProgress.expectedTotalBytes ?? 1)
                      : null,
                ),
              );
            },
              errorBuilder: (context, child, loadingProgress) {
              return Center(child: Column(
                children: [
                  Icon(Icons.image, size: 80, color: Colors.grey),
                  Text("No Image Available", style: TextStyle(color: Colors.grey, fontSize: 20, fontWeight: FontWeight.w600),)
                ],
              ));
              },
            ),
          ),

          SizedBox(
            height: 15,
          ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  project.name,
                  style: const TextStyle(
                    color: AppColors.buttonBorderColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),

              SizedBox(
                width: 8,
              ),

              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: _statusChip(project.status),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // const Icon(Icons.location_on, size: 16, color: Colors.grey),
              // const SizedBox(width: 4),
              Expanded(
                child: Text(
                  project.location,
                  style: const TextStyle(
                    color: AppColors.primaryTextColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            project.description,
            style: const TextStyle(
              color: AppColors.primaryTextColor,
              fontSize: 14,
            ),
          ),
          // Add Visit Button
          if(project.status == 'active')...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.go(Routes.addVisitScreen, extra: project),
                // onPressed: () => context.push(Routes.addVisitScreen, extra: project),
                // onPressed: () => AddVisitDialog(project: project),
                // onPressed: () => _showAddVisitDialog(project),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Visit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ]

        ],
      ),
    );
  }

  // Tablet Projects List Widget
  Widget _buildTabletProjectsList(List<Project> projects) {
    return Column(
      children: [
        const SizedBox(height: 15),
        ...projects.map((project) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
          child: Card(
            elevation: 0,
            color: Colors.grey[50],
            child: ListTile(
              title: Text(
                project.name,
                style: const TextStyle(
                  color: AppColors.primaryTextColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    project.location,
                    style: const TextStyle(color: AppColors.primaryTextColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    project.description,
                    style: const TextStyle(color: AppColors.primaryTextColor),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _statusChip(project.status),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.orange),
                    onPressed: () => AddVisitDialog(project: project),
                    // onPressed: () => _showAddVisitDialog(project),
                  ),
                ],
              ),
              onTap: () {
                debugPrint("Project tapped: ${project.name}");
              },
            ),
          ),
        )).toList(),
        const SizedBox(height: 15),
      ],
    );
  }

  // Desktop Projects Table Widget
  Widget _buildDesktopProjectsTable(List<Project> projects) {
    return Column(
      children: [
        const SizedBox(height: 15),
        SizedBox(
          width: double.infinity,
          child: DataTable(
            columnSpacing: 20,
            showCheckboxColumn: false,
            columns: const [
              DataColumn(
                label: Text(
                  "Project\nName",
                  style: TextStyle(
                    color: AppColors.primaryTextColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  "Location",
                  style: TextStyle(color: AppColors.primaryTextColor),
                ),
              ),
              DataColumn(
                label: Text(
                  "Description",
                  style: TextStyle(color: AppColors.primaryTextColor),
                ),
              ),
              DataColumn(
                label: Text(
                  "Status",
                  style: TextStyle(color: AppColors.primaryTextColor),
                ),
              ),
              DataColumn(
                label: Text(
                  "Actions",
                  style: TextStyle(color: AppColors.primaryTextColor),
                ),
              ),
            ],
            rows: projects.asMap().entries.map((entry) {
              final index = entry.key;
              final project = entry.value;

              return DataRow(
                onSelectChanged: (selected) {
                  if (selected ?? false) {
                    debugPrint("Row tapped at index: $index, Project: ${project.name}");
                  }
                },
                cells: [
                  DataCell(
                    Text(
                      project.name,
                      maxLines: 2,
                      style: const TextStyle(
                        color: AppColors.primaryTextColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      project.location,
                      style: const TextStyle(color: AppColors.primaryTextColor, fontSize: 15,),
                    ),
                  ),
                  DataCell(
                    Text(
                      project.description,
                      style: const TextStyle(color: AppColors.primaryTextColor, fontSize: 15,),
                    ),
                  ),
                  DataCell(_statusChip(project.status)),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.orange),
                      onPressed: () => AddVisitDialog(project: project),
                      // onPressed: () => _showAddVisitDialog(project),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // Show Add Visit Dialog
  void _showAddVisitDialog(Project project) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddVisitDialog(project: project);
      },
    ).then((result) {
      if (result != null) {
        // Handle the result from the dialog
        debugPrint("Visit added for project: ${project.name}");
        debugPrint("Visitor: ${result['visitorName']}");
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Visit added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }
}