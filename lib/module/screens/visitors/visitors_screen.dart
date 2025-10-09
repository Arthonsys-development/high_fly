import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/constant/app_colors.dart';
import '../../../config/constant/const_assets.dart';
import '../../../config/routes.dart';
import '../../../config/utils.dart';
import '../../../data/models/response_model/visit_response_model.dart';
import '../../global/widgets/custom_button.dart';
import '../../providers/visits_provider.dart';
import '../../utils/responsive.dart';

class VisitorsScreen extends ConsumerStatefulWidget {
  const VisitorsScreen({super.key});

  @override
  ConsumerState<VisitorsScreen> createState() => _VisitorsScreenState();
}

class _VisitorsScreenState extends ConsumerState<VisitorsScreen>
    with WidgetsBindingObserver {
  String selectedFilter = "All";
  final List<String> filterOptions = ["All", "Scheduled", "Confirmed", "Completed", "Pending"];
  bool _isDisposed = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Load visits when the screen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed && mounted) {
        ref.read(visitsControllerProvider.notifier).loadVisits();
      }
    });
    
    // Add listener to search controller
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {

    });(() {
      _searchQuery = _searchController.text.trim();
    });
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
        ref.read(visitsControllerProvider.notifier).loadVisits();
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    // Clean up any resources if needed
    super.dispose();
  }

  List<Visit> _getFilteredVisits(List<Visit> visits) {
    if (_isDisposed || !mounted) return [];
    
    // Apply search filter first
    List<Visit> searchFilteredVisits = visits;
    if (_searchQuery.isNotEmpty) {
      searchFilteredVisits = visits.where((visit) {
        return visit.projectName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               visit.visitorName.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    // Then apply status filter
    if (selectedFilter == "All") return searchFilteredVisits;
    return searchFilteredVisits.where((visit) => visit.status == selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Responsive(
      mobile: _buildMobileLayout(),
      tablet: _buildMobileLayout(),
      desktop: _buildDesktopLayout(),
    );
  }

  Widget _buildMobileLayout() {
    final visitsState = ref.watch(visitsControllerProvider);
    
    if (visitsState.isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    
    if (visitsState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: ${visitsState.error}', style: TextStyle(color: Colors.black),),
            ElevatedButton(
              onPressed: () {
                if (!_isDisposed && mounted) {
                  ref.read(visitsControllerProvider.notifier).loadVisits();
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    final filteredVisits = _getFilteredVisits(visitsState.visits);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Visits",
            style: TextStyle(
              color: AppColors.primaryTextColor,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),

          // Search field
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: SizedBox(
              height: 50,
              child: TextField(
                controller: _searchController,
                cursorColor: AppColors.primaryTextColor,
                style: const TextStyle(fontSize: 14, color: AppColors.primaryTextColor),
                decoration: InputDecoration(
                  hintText: "Search by project or visitor name...",
                  prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.primaryTextColor,),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppColors.secondaryTextColor,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppColors.secondaryTextColor,
                      width: 1,
                    ),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),

          // Show empty state message when there are no visits
          if (filteredVisits.isEmpty)
            _buildEmptyStateMessage()
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: filteredVisits
                    .map((visit) => _buildMobileVisitorCard(visit))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    final visitsState = ref.watch(visitsControllerProvider);
    
    if (visitsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (visitsState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: ${visitsState.error}'),
            ElevatedButton(
              onPressed: () {
                if (!_isDisposed && mounted) {
                  ref.read(visitsControllerProvider.notifier).loadVisits();
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    final filteredVisits = _getFilteredVisits(visitsState.visits);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Visits",
                style: TextStyle(
                  color: AppColors.primaryTextColor,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Search field for desktop
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: SizedBox(
              width: MediaQuery.of(context).size.width / 3,
              height: 50,
              child: TextField(
                controller: _searchController,
                cursorColor: AppColors.primaryTextColor,
                style: const TextStyle(fontSize: 14, color: AppColors.primaryTextColor),
                decoration: InputDecoration(
                  hintText: "Search by project or visitor name...",
                  prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.primaryTextColor,),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppColors.secondaryTextColor,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppColors.secondaryTextColor,
                      width: 1,
                    ),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),

          // Show empty state message when there are no visits
          if (filteredVisits.isEmpty)
            _buildEmptyStateMessage()
          else
            _buildVisitorsTable(filteredVisits),
        ],
      ),
    );
  }

  Widget _buildMobileVisitorCard(Visit visit) {
    return GestureDetector(
      onTap: () {
        if (!_isDisposed && mounted) {
          // Navigate to visit detail screen instead of showing dialog
          context.push(Routes.visitDetailScreen, extra: visit);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      border: Border.all(color: AppColors.primaryTextColor),
                      borderRadius: BorderRadius.circular(10)
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadiusGeometry.circular(10),
                      child: visit.visitorPhoto != null && visit.visitorPhoto!.isNotEmpty
                          ? Image.network(
                                visit.visitorPhoto!,
                                fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback to default image if network image fails
                          return  Icon(Icons.image, size: 40, color: Colors.grey);
                        },
                                loadingBuilder: (context, child, loadingProgress) {
                                  // Show loading indicator while image is loading
                                  if (loadingProgress == null) return child;
                                  return const Center(
                                    child: SizedBox(
                                      height: 30,
                                      width: 30,
                                      child: CircularProgressIndicator(
                                        color: AppColors.primaryColor,
                                        strokeWidth: 2,
                                        value: null, // Indeterminate progress
                                      ),
                                    ),
                                  );
                                },
                            )
                          : Image.asset(ImageAssets.highFlyLogo),
                    ),
                  ),
                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          visit.projectName,
                          style: const TextStyle(
                            color: AppColors.primaryTextColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),

                        Text(
                          visit.visitorName,
                          style: const TextStyle(
                            color: AppColors.primaryTextColor,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),

                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              Utils.formatDateTime(visit.visitDateTime),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(
                height: 8,
              ),

              if (visit.comments != null && visit.comments!.isNotEmpty)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Comment:  ",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w600
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),Flexible(
                      child: Text(
                        visit.comments!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        // overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisitorsTable(List<Visit> visits) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 40),
              child: DataTable(
                showCheckboxColumn: false,
                columnSpacing: 20,
                columns: const [
                  DataColumn(
                    label: Text(
                      "Project",
                      style: TextStyle(
                        color: AppColors.primaryTextColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "Visitor",
                      style: TextStyle(
                        color: AppColors.primaryTextColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "Date & Time",
                      style: TextStyle(color: AppColors.primaryTextColor),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "Photo",
                      style: TextStyle(color: AppColors.primaryTextColor),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "Comments",
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
                rows: visits.map((visit) {
                  return DataRow(
                    cells: [
                      DataCell(Text(visit.projectName)),
                      DataCell(Text(visit.visitorName)),
                      // DataCell(Text("${visit.visitDate.toString().split(' ')[0]}\n${visit.visitTime}")),
                      DataCell(Text(Utils.formatDateTime(visit.visitDateTime))),
                      DataCell(
                        visit.visitorPhoto != null && visit.visitorPhoto!.isNotEmpty
                            ? Container(
                                height: 40,
                                width: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                ),
                                child: ClipOval(
                                  child: Image.network(
                                    visit.visitorPhoto!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      // Fallback to default image if network image fails
                                      return  Icon(Icons.image, size: 40, color: Colors.grey);
                                    },
                                    loadingBuilder: (context, child, loadingProgress) {
                                      // Show loading indicator while image is loading
                                      if (loadingProgress == null) return child;
                                      return const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          value: null, // Indeterminate progress
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              )
                            : Container(
                                height: 40,
                                width: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    ImageAssets.highFlyLogo,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 200,
                          child: Text(
                            visit.comments ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.visibility),
                          onPressed: () {
                            if (!_isDisposed && mounted) {
                              // Navigate to visit detail screen instead of showing dialog
                              context.push(Routes.visitDetailScreen, extra: visit);
                            }
                          },
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a user-friendly empty state message when there are no visitors
  Widget _buildEmptyStateMessage() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32.0),
        margin: const EdgeInsets.only(top: 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.group_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              "No Visits Found",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryTextColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "There are currently no visit records to display.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Visits will appear here once they are scheduled or checked in.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: "Refresh Data",
              onPressed: () {
                if (!_isDisposed && mounted) {
                  ref.read(visitsControllerProvider.notifier).loadVisits();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}