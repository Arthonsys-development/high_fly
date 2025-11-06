import 'package:flutter/material.dart';
import 'package:highfly/config/constant/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:highfly/config/constant/const_assets.dart';
import 'package:highfly/module/providers/projects_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:highfly/config/routes.dart';
import 'package:highfly/data/models/response_model/project_response_model.dart';
import 'package:highfly/module/screens/profile/profile_screen.dart';

import '../../utils/responsive.dart';
import '../../widgets/dashboard_side_menu.dart';
import '../Booking/BookingScreen.dart';
import '../visitors/visitors_screen.dart';
import '../holds/holds_list_screen.dart';
import '../bookings/bookings_list_screen.dart';
import '../bookings/webview_screen.dart';
import '../../providers/analytics_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with WidgetsBindingObserver {
  int selectedMenuIndex = 0;
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
        // Log dashboard view analytics
        try {
          final analyticsService = ref.read(analyticsProvider);
          analyticsService.logDashboardViewed();
        } catch (e) {
          debugPrint('Error logging dashboard view analytics: $e');
        }
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

  Future<void> _openGoogleMaps(Project project) async {
    if (project.latitude == null || project.longitude == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location coordinates not available for this project'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Create Google Maps web URL
    // The WebView will handle intent:// redirects and extract the fallback URL
    final googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=${project.latitude},${project.longitude}';
    
    // Navigate to WebViewScreen to display Google Maps in-app
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WebViewScreen(
            url: googleMapsUrl,
            title: '${project.name} - Location',
          ),
        ),
      );
    }
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Logout',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryTextColor,
            ),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.secondaryTextColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.secondaryTextColor,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                // Sign out from Firebase
                await FirebaseAuth.instance.signOut();
                // Clear access token from secure storage
                const secureStorage = FlutterSecureStorage();
                await secureStorage.deleteAll();
                // Navigate back to sign in screen
                if (mounted) {
                  context.go(Routes.signIn);
                }
              },
              child: const Text(
                'Logout',
                style: TextStyle(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
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
                icon: const Icon(Icons.list, color:  AppColors.primaryColor),
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
            icon: const Icon(Icons.logout, color: AppColors.primaryColor),
            onPressed: () {
              _showLogoutConfirmationDialog(context);
            },
          ),
        ],
      ),
    );
  }

  String _getPageTitle() {
    switch (selectedMenuIndex) {
      case 0:
        return 'Vistarak - Projects';
      case 1:
        return 'Vistarak - Visits';
      case 2:
        return 'Vistarak - Booking';
      case 3:
        return 'Vistarak - Holds';
      case 4:
        return 'Vistarak - Bookings';
      case 5:
        return 'Vistarak - Profile';
      default:
        return 'Vistarak Dashboard';
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
      case 3:
        return _buildHoldsContent();
      case 4:
        return _buildBookingsContent();
      case 5:
        return _buildProfileContent();
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

  Widget _buildProfileContent() {
    return const ProfileScreen();
  }

  Widget _buildBookingProcessorContent() {
    return BookingProcessorScreen();
  }

  Widget _buildHoldsContent() {
    return const HoldsListScreen();
  }

  Widget _buildBookingsContent() {
    return const BookingsListScreen();
  }

  Widget _buildMobileLayout() {
    final projectsState = ref.watch(projectsControllerProvider);
    final filteredProjects = _filterProjects(projectsState.projects, _searchQuery);

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          ref.read(projectsControllerProvider.notifier).loadProjects(),
          ref.read(projectsControllerProvider.notifier).loadActiveProjects(),
        ]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
              //   icon: const Icon(Icons.refresh, color:  AppColors.primaryColor),
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
                icon: IconsAssets.totalProjectIcon,
                color:  AppColors.primaryColor,
              ),
              _statsCard(
                context,
                title: "Active Projects",
                count: projectsState.activeProjects.length.toString(),
                icon: IconsAssets.activeProjectIcon,
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
                  child: Row(
                    children: [
                      Expanded(
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

                      /*Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color.fromARGB(0, 240, 89, 34),
                                width: 2,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: Image.asset(IconsAssets.listViewIcon, color: AppColors.primaryColor),
                            ),
                          ),

                          SizedBox(
                            width: 5,
                          ),

                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color.fromARGB(0, 240, 89, 34),
                                width: 2,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: Image.asset(IconsAssets.listViewIcon, color: AppColors.primaryColor),
                            ),
                          ),
                        ],
                      )*/
                    ],
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
                  ...filteredProjects.map((project) => _buildMobileProjectCard(project)),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildTabletDesktopLayout() {
    final isTablet = Responsive.isTablet(context);
    final isDesktop = Responsive.isDesktop(context);
    final projectsState = ref.watch(projectsControllerProvider);
    final filteredProjects = _filterProjects(projectsState.projects, _searchQuery);

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          ref.read(projectsControllerProvider.notifier).loadProjects(),
          ref.read(projectsControllerProvider.notifier).loadActiveProjects(),
        ]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                icon: const Icon(Icons.refresh, color:  AppColors.primaryColor),
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
                      icon: IconsAssets.totalProjectIcon,
                      color:  AppColors.primaryColor,
                    ),
                    const SizedBox(height: 12),
                    _statsCard(
                      context,
                      title: "Active Projects",
                      count: projectsState.activeProjects.length.toString(),
                      icon: IconsAssets.activeProjectIcon,
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
                        icon: IconsAssets.totalProjectIcon,
                        color:  AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _statsCard(
                        context,
                        title: "Active Projects",
                        count: projectsState.activeProjects.length.toString(),
                        icon: IconsAssets.activeProjectIcon,
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
        required String icon,
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
                    child: Image.asset(icon, width: 20, height: 20, color: color,),
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
    return /*Icon(Icons.circle, size: 15, color: text == 'active' ? Colors.green : Colors.red);*/
      Container(
        // height: 25,
        decoration: BoxDecoration(
          color: text == 'active' ? AppColors.successColor : text == 'inactive' ? Colors.red : AppColors.buttonBorderColor,
          borderRadius: BorderRadius.all(Radius.circular(25)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13.0, vertical: 5),
          child: Text(
            text.toUpperCase(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
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
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadiusGeometry.all(Radius.circular(5)),
                child: Image.network(
                project.projectImage, // sample image url
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


              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0, right: 8.0),
                  child: _statusChip(project.status),
                ),
              ),
            ],
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
                    color: AppColors.primaryTextColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 18,
                  ),
                ),
              ),

            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _openGoogleMaps(project),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
               // crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(IconsAssets.locationIcon, width: 15, color: const Color.fromARGB(255, 66, 76, 90)),
                  // const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      project.subAddress,
                      style: const TextStyle(
                        color: AppColors.darkGreyColor,
                        fontWeight: FontWeight.normal,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
    if(project.description.isNotEmpty)...[
    RichText(
      text: TextSpan(
        text: 'Description: ',
        style: const TextStyle(color: AppColors.darkGreyColor,  fontSize: 16, fontWeight: FontWeight.w500),
        children: [
          TextSpan(
            text: project.description,
              style: const TextStyle(color: AppColors.darkGreyColor,  fontSize: 16, fontWeight: FontWeight.w400),
          ),
        ],
      ),
    )
    ],

          // Add Visit Button
          if(project.status == 'active')...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.go(Routes.addVisitScreen, extra: project),
                // onPressed: () => context.push(Routes.addVisitScreen, extra: project),
                // onPressed: () => AddVisitDialog(project: project),
                // onPressed: () => context.go(Routes.addVisitScreen, extra: project),
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
                    icon: const Icon(Icons.add, color:  AppColors.primaryColor),
                    onPressed: () => context.go(Routes.addVisitScreen, extra: project),
                  ),
                ],
              ),
              onTap: () {
                debugPrint("Project tapped: ${project.name}");
              },
            ),
          ),
        )),
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
                      icon: const Icon(Icons.add, color:  AppColors.primaryColor),
                      onPressed: () => context.go(Routes.addVisitScreen, extra: project),
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

}