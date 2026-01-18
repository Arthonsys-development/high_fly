import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
import 'package:highfly/data/repository/auth_api_repository.dart';

import '../../utils/responsive.dart';
import '../../widgets/dashboard_side_menu.dart';
import '../Booking/BookingScreen.dart';
import '../visitors/visitors_screen.dart';
import '../holds/holds_list_screen.dart';
import '../bookings/bookings_list_screen.dart';
import '../bookings/webview_screen.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/booking_navigation_provider.dart';
// Conditional import for web image widget
import '../visitors/web_image_widget.dart' if (dart.library.io) '../visitors/web_image_widget_stub.dart';

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
  String? _selectedStatusFilter; // null means "All"
  bool _isDisposed = false;
  final ScrollController _mobileScrollController = ScrollController();
  final ScrollController _tabletDesktopScrollController = ScrollController();

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
    _mobileScrollController.dispose();
    _tabletDesktopScrollController.dispose();
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
                try {
                  // Call logout API
                  final authRepository = AuthApiRepository();
                  final result = await authRepository.logout();
                  
                  if (result['success'] == true) {
                    debugPrint('Logout API call successful');
                  } else {
                    debugPrint('Logout API call failed: ${result['message']}');
                    // Continue with logout even if API call fails
                  }
                } catch (e) {
                  debugPrint('Error calling logout API: $e');
                  // Continue with logout even if API call fails
                }
                
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
    return projects.where((project) {
      // Filter by status first
      if (_selectedStatusFilter != null && 
          project.status.toLowerCase() != _selectedStatusFilter!.toLowerCase()) {
        return false;
      }
      
      // Filter by search query
      if (query.isNotEmpty) {
        return project.name.toLowerCase().contains(query) ||
               project.location.toLowerCase().contains(query) ||
               (project.subAddress.isNotEmpty && 
                project.subAddress.toLowerCase().contains(query)) ||
               project.description.toLowerCase().contains(query) ||
               project.status.toLowerCase().contains(query);
      }
      
      return true;
    }).toList();
  }

  bool _hasAvailablePlots(Project project) {
    return (project.availablePlotCount ?? 0) > 0;
  }

  void _showNoPlotsAvailableAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'No Plots Available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryTextColor,
            ),
          ),
          content: const Text(
            'There are no available plots for this project. Please try another project.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.secondaryTextColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'OK',
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
            color: Colors.grey.withValues(alpha: 0.1),
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

          //const SizedBox(width: 12),
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
        return 'Projects';
      case 1:
        return 'Visits';
      case 2:
        return 'Booking';
      case 3:
        return 'Holds';
      case 4:
        return 'Bookings';
      case 5:
        return 'Profile';
      default:
        return 'Dashboard';
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
        controller: _mobileScrollController,
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
                subtitleLeft: null,
                subtitleRight: null,
                icon: IconsAssets.totalProjectIcon,
                color: AppColors.primaryColor,
                isDesktop: false,
              ),
              const SizedBox(width: 5),
              _statsCard(
                context,
                title: "Active Projects",
                count: projectsState.activeProjects.length.toString(),
                icon: IconsAssets.activeProjectIcon,
                color: Colors.green,
                isDesktop: false,
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
                // Search Bar and Status Filter - Full width on mobile
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    children: [
                      Row(
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
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Status Filter Dropdown
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.secondaryTextColor,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedStatusFilter,
                          dropdownColor: Colors.white,
                          decoration: InputDecoration(
                            hintText: "Filter by Status",
                            hintStyle: const TextStyle(fontSize: 14, color: AppColors.secondaryTextColor),
                            prefixIcon: const Icon(Icons.filter_list, size: 20, color: AppColors.primaryTextColor),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('All Status', style: TextStyle(fontSize: 14, color: AppColors.primaryTextColor)),
                            ),
                            const DropdownMenuItem<String>(
                              value: 'active',
                              child: Text('Active', style: TextStyle(fontSize: 14, color: AppColors.primaryTextColor)),
                            ),
                            const DropdownMenuItem<String>(
                              value: 'inactive',
                              child: Text('Inactive', style: TextStyle(fontSize: 14, color: AppColors.primaryTextColor)),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedStatusFilter = value;
                            });
                          },
                          isExpanded: true,
                        ),
                      ),
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
    final maxContentWidth = isDesktop ? 1400.0 : double.infinity;

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          ref.read(projectsControllerProvider.notifier).loadProjects(),
          ref.read(projectsControllerProvider.notifier).loadActiveProjects(),
        ]);
      },
      child: SingleChildScrollView(
        controller: _tabletDesktopScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 20.0 : isDesktop ? 40.0 : 24.0,
          vertical: isTablet ? 16.0 : 24.0,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section with Title and Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Projects",
                          style: TextStyle(
                            color: AppColors.primaryTextColor,
                            fontSize: isTablet ? 28 : 32,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Manage and view all your projects",
                          style: TextStyle(
                            color: AppColors.secondaryTextColor,
                            fontSize: isTablet ? 14 : 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.refresh, color: AppColors.primaryColor),
                        tooltip: "Refresh projects",
                        onPressed: () {
                          ref.read(projectsControllerProvider.notifier).loadProjects();
                          ref.read(projectsControllerProvider.notifier).loadActiveProjects();
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Stats Cards - Enhanced design
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
                            color: AppColors.primaryColor,
                            isDesktop: isDesktop,
                          ),
                          const SizedBox(height: 16),
                          _statsCard(
                            context,
                            title: "Active Projects",
                            count: projectsState.activeProjects.length.toString(),
                            icon: IconsAssets.activeProjectIcon,
                            color: Colors.green,
                            isDesktop: isDesktop,
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
                              subtitleLeft: null,
                              subtitleRight: null,
                              icon: IconsAssets.totalProjectIcon,
                              color: AppColors.primaryColor,
                              isDesktop: isDesktop,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _statsCard(
                              context,
                              title: "Active Projects",
                              count: projectsState.activeProjects.length.toString(),
                              icon: IconsAssets.activeProjectIcon,
                              color: Colors.green,
                              isDesktop: isDesktop,
                            ),
                          ),
                        ],
                      ),

                const SizedBox(height: 32),

                // Projects Table Container - Enhanced
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search Bar Section - Enhanced
                      Container(
                        padding: const EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.textFieldBGColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  cursorColor: AppColors.primaryColor,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: AppColors.primaryTextColor,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: "Search projects by name, location, or description...",
                                    hintStyle: TextStyle(
                                      color: AppColors.secondaryTextColor.withValues(alpha: 0.6),
                                      fontSize: 15,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.search,
                                      size: 22,
                                      color: AppColors.secondaryTextColor,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Status Filter Dropdown
                            Container(
                              width: isDesktop ? 200 : 180,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.textFieldBGColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedStatusFilter,
                                dropdownColor: Colors.white,
                                decoration: InputDecoration(
                                  hintText: "Filter by Status",
                                  hintStyle: TextStyle(
                                    color: AppColors.secondaryTextColor.withValues(alpha: 0.6),
                                    fontSize: 15,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.filter_list,
                                    size: 22,
                                    color: AppColors.secondaryTextColor,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                                items: [
                                  const DropdownMenuItem<String>(
                                    value: null,
                                    child: Text('All Status', style: TextStyle(fontSize: 15, color: AppColors.primaryTextColor)),
                                  ),
                                  const DropdownMenuItem<String>(
                                    value: 'active',
                                    child: Text('Active', style: TextStyle(fontSize: 15, color: AppColors.primaryTextColor)),
                                  ),
                                  const DropdownMenuItem<String>(
                                    value: 'inactive',
                                    child: Text('Inactive', style: TextStyle(fontSize: 15, color: AppColors.primaryTextColor)),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedStatusFilter = value;
                                  });
                                },
                                isExpanded: true,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Show loading indicator
                      if (projectsState.isLoading)
                        Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Center(
                            child: Column(
                              children: [
                                const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Loading projects...',
                                  style: TextStyle(
                                    color: AppColors.secondaryTextColor,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Show error message if any
                      if (projectsState.error != null)
                        Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Colors.red[300],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Error loading projects',
                                  style: TextStyle(
                                    color: Colors.red[700],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  projectsState.error!,
                                  style: TextStyle(
                                    color: AppColors.secondaryTextColor,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    ref.read(projectsControllerProvider.notifier).loadProjects();
                                    ref.read(projectsControllerProvider.notifier).loadActiveProjects();
                                  },
                                  icon: const Icon(Icons.refresh, size: 18),
                                  label: const Text('Retry'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Show empty state if no projects and no errors
                      if (!projectsState.isLoading && 
                          projectsState.error == null && 
                          filteredProjects.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(60.0),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 72,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'No projects found',
                                  style: TextStyle(
                                    color: AppColors.primaryTextColor,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _searchQuery.isEmpty
                                      ? 'Get started by adding your first project'
                                      : 'Try adjusting your search terms',
                                  style: TextStyle(
                                    color: AppColors.secondaryTextColor,
                                    fontSize: 15,
                                  ),
                                ),
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
        ),
      ),
    );
  }

  Widget _statsCard(BuildContext context,
      {required String title,
        required String count,
        String? subtitleLeft,
        String? subtitleRight,
        required String icon,
        required Color color,
        bool isDesktop = false}) {
    final isMobile = Responsive.isMobile(context);
    
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : isDesktop ? 24 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: AppColors.secondaryTextColor,
                            fontSize: isMobile ? 13 : isDesktop ? 15 : 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          count,
                          style: TextStyle(
                            color: AppColors.primaryTextColor,
                            fontSize: isMobile ? 28 : isDesktop ? 36 : 32,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(isMobile ? 10 : isDesktop ? 14 : 12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.asset(
                      icon,
                      width: isDesktop ? 28 : 24,
                      height: isDesktop ? 28 : 24,
                      color: color,
                    ),
                  ),
                ],
              ),
              if (subtitleLeft != null && subtitleRight != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        subtitleLeft,
                        style: TextStyle(
                          color: AppColors.secondaryTextColor,
                          fontSize: isDesktop ? 13 : 12,
                        ),
                      ),
                      Text(
                        subtitleRight,
                        style: TextStyle(
                          color: AppColors.secondaryTextColor,
                          fontSize: isDesktop ? 13 : 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String text) {
    return Container(
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
    return InkWell(
      onTap: () => context.push(Routes.projectDetailScreen, extra: project),
      borderRadius: BorderRadius.circular(8),
      child: Container(
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
                child: kIsWeb
                    ? WebImageWidget(
                        imageUrl: project.projectImage,
                        width: MediaQuery.of(context).size.width - 65 - 32, // Screen width - container margins (15*2) - container padding (16*2)
                        height: 200,
                        borderRadius: 20,
                        fit: Responsive.isLargeMobile(context) ? BoxFit.contain : BoxFit.cover,
                      )
                    : Image.network(
                        project.projectImage, // sample image url
                        width: double.infinity, // Fill available width within parent container
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

              // Transparent overlay to capture taps on web
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => context.push(Routes.projectDetailScreen, extra: project),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    color: Colors.transparent,
                  ),
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
            onTap: () {
              // Stop event propagation to prevent card navigation
              _openGoogleMaps(project);
            },
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
               // crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image.asset(IconsAssets.locationIcon, width: 15, color: const Color.fromARGB(255, 66, 76, 90)),
                  const Icon(Icons.location_on_outlined, size: 22, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      project.subAddress != "" ? project.subAddress : project.location != "" ? project.location : "No location available",
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

          // Action Buttons for Active Projects
          if(project.status == 'active')...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _hasAvailablePlots(project) ? () {
                      // Set booking navigation with project and Book Now tab (index 0)
                      ref.read(bookingNavigationProvider.notifier).navigateToBooking(project, 0);
                      // Switch to booking tab in dashboard
                      setState(() {
                        selectedMenuIndex = 2;
                      });
                    } : () {
                      _showNoPlotsAvailableAlert(context);
                    },
                    icon: const Icon(Icons.bookmark, size: 18),
                    label: const Text('Book Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _hasAvailablePlots(project) 
                          ? AppColors.primaryColor 
                          : Colors.grey,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _hasAvailablePlots(project) ? () {
                      // Set booking navigation with project and Hold tab (index 1)
                      ref.read(bookingNavigationProvider.notifier).navigateToBooking(project, 1);
                      // Switch to booking tab in dashboard
                      setState(() {
                        selectedMenuIndex = 2;
                      });
                    } : () {
                      _showNoPlotsAvailableAlert(context);
                    },
                    icon: const Icon(Icons.access_time, size: 18),
                    label: const Text('Hold'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _hasAvailablePlots(project) 
                          ? Colors.orange 
                          : Colors.grey,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.go(Routes.addVisitScreen, extra: project),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Visit'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryColor,
                  side: const BorderSide(color: AppColors.primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ]

        ],
        ),
      ),
    );
  }

  // Tablet Projects List Widget
  Widget _buildTabletProjectsList(List<Project> projects) {
    return Column(
      children: [
        const SizedBox(height: 8),
        ...projects.map((project) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push(Routes.projectDetailScreen, extra: project),
                borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            project.name,
                            style: const TextStyle(
                              color: AppColors.primaryTextColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: AppColors.secondaryTextColor,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  project.location,
                                  style: const TextStyle(
                                    color: AppColors.secondaryTextColor,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (project.description.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              project.description,
                              style: const TextStyle(
                                color: AppColors.secondaryTextColor,
                                fontSize: 13,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _statusChip(project.status),
                        const SizedBox(height: 8),
                        if (project.status == 'active') ...[
                          // Book Now button
                          Container(
                            decoration: BoxDecoration(
                              color: _hasAvailablePlots(project) 
                                  ? AppColors.primaryColor.withValues(alpha: 0.1)
                                  : Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _hasAvailablePlots(project) ? () {
                                  ref.read(bookingNavigationProvider.notifier).navigateToBooking(project, 0);
                                  onMenuItemSelected(2);
                                } : () {
                                  _showNoPlotsAvailableAlert(context);
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.bookmark,
                                        size: 18,
                                        color: _hasAvailablePlots(project) 
                                            ? AppColors.primaryColor 
                                            : Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Book Now',
                                        style: TextStyle(
                                          color: _hasAvailablePlots(project) 
                                              ? AppColors.primaryColor 
                                              : Colors.grey,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Hold button
                          Container(
                            decoration: BoxDecoration(
                              color: _hasAvailablePlots(project) 
                                  ? Colors.orange.withValues(alpha: 0.1)
                                  : Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _hasAvailablePlots(project) ? () {
                                  ref.read(bookingNavigationProvider.notifier).navigateToBooking(project, 1);
                                  onMenuItemSelected(2);
                                } : () {
                                  _showNoPlotsAvailableAlert(context);
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 18,
                                        color: _hasAvailablePlots(project) 
                                            ? Colors.orange 
                                            : Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Hold',
                                        style: TextStyle(
                                          color: _hasAvailablePlots(project) 
                                              ? Colors.orange 
                                              : Colors.grey,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Add Visit button
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => context.go(Routes.addVisitScreen, extra: project),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.add,
                                        size: 18,
                                        color: AppColors.primaryColor,
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'Add Visit',
                                        style: TextStyle(
                                          color: AppColors.primaryColor,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        )),
        const SizedBox(height: 20),
      ],
    );
  }

  // Desktop Projects Table Widget
  Widget _buildDesktopProjectsTable(List<Project> projects) {
    return Column(
      children: [
        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.textFieldBGColor,
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  "Project Name",
                  style: TextStyle(
                    color: AppColors.primaryTextColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  "Location",
                  style: TextStyle(
                    color: AppColors.primaryTextColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  "Description",
                  style: TextStyle(
                    color: AppColors.primaryTextColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  "Status",
                  style: TextStyle(
                    color: AppColors.primaryTextColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  "Actions",
                  style: TextStyle(
                    color: AppColors.primaryTextColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Table Rows
        ...projects.map((project) {

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 0),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push(Routes.projectDetailScreen, extra: project),
                hoverColor: AppColors.textFieldBGColor.withValues(alpha: 0.5),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          project.name,
                          maxLines: 2,
                          style: const TextStyle(
                            color: AppColors.primaryTextColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            overflow: TextOverflow.ellipsis,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 18,
                              color: AppColors.secondaryTextColor,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                               project.subAddress != "" ? project.subAddress : project.location != "" ? project.location : "No location available",
                                style: const TextStyle(
                                  color: AppColors.primaryTextColor,
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 3,
                        child: Text(
                          project.description,
                          style: TextStyle(
                            color: AppColors.secondaryTextColor,
                            fontSize: 14,
                            height: 1.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: _statusChip(project.status),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: project.status == 'active'
                            ? Row(
                                children: [
                                  // Book Now button
                                  Container(
                                    width: 40,
                                    decoration: BoxDecoration(
                                      color: _hasAvailablePlots(project) 
                                          ? AppColors.primaryColor.withValues(alpha: 0.1)
                                          : Colors.grey.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _hasAvailablePlots(project) ? () {
                                          ref.read(bookingNavigationProvider.notifier).navigateToBooking(project, 0);
                                          onMenuItemSelected(2);
                                        } : () {
                                          _showNoPlotsAvailableAlert(context);
                                        },
                                        borderRadius: BorderRadius.circular(8),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 8,
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.bookmark,
                                                size: 16,
                                                color: _hasAvailablePlots(project) 
                                                    ? AppColors.primaryColor 
                                                    : Colors.grey,
                                              ),
                                              // const SizedBox(width: 4),
                                              // const Text(
                                              //   'Book',
                                              //   style: TextStyle(
                                              //     color: AppColors.primaryColor,
                                              //     fontSize: 12,
                                              //     fontWeight: FontWeight.w500,
                                              //   ),
                                              // ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  // Hold button
                                  Container(
                                    width: 40,
                                    decoration: BoxDecoration(
                                      color: _hasAvailablePlots(project) 
                                          ? Colors.orange.withValues(alpha: 0.1)
                                          : Colors.grey.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _hasAvailablePlots(project) ? () {
                                          ref.read(bookingNavigationProvider.notifier).navigateToBooking(project, 1);
                                          onMenuItemSelected(2);
                                        } : () {
                                          _showNoPlotsAvailableAlert(context);
                                        },
                                        borderRadius: BorderRadius.circular(8),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 8,
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.access_time,
                                                size: 16,
                                                color: _hasAvailablePlots(project) 
                                                    ? Colors.orange 
                                                    : Colors.grey,
                                              ),
                                              // const SizedBox(width: 4),
                                              // const Text(
                                              //   'Hold',
                                              //   style: TextStyle(
                                              //     color: Colors.orange,
                                              //     fontSize: 12,
                                              //     fontWeight: FontWeight.w500,
                                              //   ),
                                              // ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  // Add Visit button
                                  Container(
                                    width: 40,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => context.go(Routes.addVisitScreen, extra: project),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 8,
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.add,
                                                size: 16,
                                                color: AppColors.primaryColor,
                                              ),
                                              // const SizedBox(width: 4),
                                              // const Text(
                                              //   'Add Visit',
                                              //   style: TextStyle(
                                              //     color: AppColors.primaryColor,
                                              //     fontSize: 12,
                                              //     fontWeight: FontWeight.w500,
                                              //   ),
                                              // ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.block,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Inactive',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
      ],
    );
  }

}