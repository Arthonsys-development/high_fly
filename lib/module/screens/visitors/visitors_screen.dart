import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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

// Conditional import for web image widget
import 'web_image_widget.dart' if (dart.library.io) 'web_image_widget_stub.dart';

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
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _searchController,
                cursorColor: AppColors.primaryColor,
                style: TextStyle(color: AppColors.primaryColor, fontSize: 15),
                decoration: InputDecoration(
                  hintText: "Search by plot code, customer name, phone...",
                  border: InputBorder.none,
                  prefixIcon: const Icon(Icons.search, color: AppColors.primaryColor),
                ),
              ),
            ),
            const SizedBox(height: 20),
          // Padding(
          //   padding: const EdgeInsets.all(15.0),
          //   child: SizedBox(
          //     height: 50,
          //     child: TextField(
          //       controller: _searchController,
          //       cursorColor: AppColors.primaryColor,
          //       style: TextStyle(color: AppColors.primaryColor, fontSize: 15),
          //       decoration: InputDecoration(
          //         hintText: "Search by plot code, customer name, phone...",
          //         border: InputBorder.none,
          //         prefixIcon: const Icon(Icons.search, color: AppColors.primaryColor),
          //       )
          //     ),
          //   ),
          // ),

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
      padding: const EdgeInsets.all(24.0),
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
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${filteredVisits.length} ${filteredVisits.length == 1 ? 'Visit' : 'Visits'}",
                  style: const TextStyle(
                    color: AppColors.primaryTextColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Search field for desktop
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            width: MediaQuery.of(context).size.width / 3,
            child: TextField(
              controller: _searchController,
              cursorColor: AppColors.primaryColor,
              style: const TextStyle(fontSize: 14, color: AppColors.primaryTextColor),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: "Search by project or visitor name...",
                prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.primaryColor,),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: AppColors.primaryColor,
                    width: 2,
                  ),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20, color: AppColors.primaryColor),
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

          // Show empty state message when there are no visits
          if (filteredVisits.isEmpty)
            _buildEmptyStateMessage()
          else if (kIsWeb)
            _buildEnhancedVisitorsTable(filteredVisits)
          else
            _buildSimpleVisitorsTable(filteredVisits),
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
                          ? _buildWebCompatibleImage(visit.visitorPhoto!, 80, 80)
                          : Image.asset(
                              ImageAssets.highFlyLogo,
                              fit: BoxFit.cover,
                              width: 80,
                              height: 80,
                            ),
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

  Widget _buildSimpleVisitorsTable(List<Visit> visits) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
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
                  DataCell(Text(Utils.formatDateTime(visit.visitDateTime))),
                  DataCell(
                    visit.visitorPhoto != null && visit.visitorPhoto!.isNotEmpty
                        ? Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[100],
                            ),
                            child: ClipOval(
                              child: _buildWebCompatibleImage(visit.visitorPhoto!, 40, 40),
                            ),
                          )
                        : Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[100],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                ImageAssets.highFlyLogo,
                                fit: BoxFit.cover,
                                width: 40,
                                height: 40,
                              ),
                            ),
                          ),
                  ),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.visibility),
                      onPressed: () {
                        if (!_isDisposed && mounted) {
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
    );
  }

  Widget _buildEnhancedVisitorsTable(List<Visit> visits) {
    return Container(
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
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryBackgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 120,
                  child: _buildTableHeader("Visitor Photo"),
                ),
                Expanded(
                  flex: 2,
                  child: _buildTableHeader("Visitor Name"),
                ),
                Expanded(
                  flex: 2,
                  child: _buildTableHeader("Project"),
                ),
                Expanded(
                  flex: 2,
                  child: _buildTableHeader("Date & Time"),
                ),
                SizedBox(
                  width: 100,
                  child: _buildTableHeader(""),
                ),
              ],
            ),
          ),
          
          // Table Rows
          ...visits.asMap().entries.map((entry) {
            final visit = entry.value;
            final isLast = entry.key == visits.length - 1;
            return _buildEnhancedVisitRow(visit, isLast);
          }),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.primaryTextColor,
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
    );
  }

  Widget _buildEnhancedVisitRow(Visit visit, bool isLast) {
    return InkWell(
      onTap: () {
        if (!_isDisposed && mounted) {
          context.push(Routes.visitDetailScreen, extra: visit);
        }
      },
      hoverColor: Colors.grey[50],
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey[200]!,
              width: isLast ? 0 : 1,
            ),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 120,
              child: _buildVisitorPhoto(visit.visitorPhoto),
            ),
            Expanded(
              flex: 2,
              child: Text(
                visit.visitorName,
                style: const TextStyle(
                  color: AppColors.primaryTextColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                visit.projectName,
                style: const TextStyle(
                  color: AppColors.primaryTextColor,
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                Utils.formatDateTime(visit.visitDateTime),
                style: const TextStyle(
                  color: AppColors.primaryTextColor,
                  fontSize: 13,
                ),
              ),
            ),
            SizedBox(
              width: 100,
              child: IconButton(
                icon: const Icon(Icons.more_vert, size: 20),
                color: AppColors.primaryColor,
                onPressed: () {
                  if (!_isDisposed && mounted) {
                    context.push(Routes.visitDetailScreen, extra: visit);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitorPhoto(String? photoUrl) {
    return Container(
      height: 50,
      width: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey[300]!, width: 1),
        color: Colors.grey[100],
      ),
      child: ClipOval(
        child: photoUrl != null && photoUrl.isNotEmpty
            ? _buildWebCompatibleImage(photoUrl, 50, 50)
            : Image.asset(
                ImageAssets.highFlyLogo,
                fit: BoxFit.cover,
                width: 50,
                height: 50,
              ),
      ),
    );
  }

  Widget _buildWebCompatibleImage(String imageUrl, double width, double height) {
    // Use the conditionally imported widget (web version on web, stub on mobile)
    return WebImageWidget(
      imageUrl: imageUrl,
      width: width,
      height: height,
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
