import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../config/constant/app_colors.dart';
import '../../../config/constant/const_assets.dart';
import '../../../config/routes.dart';
import '../../../config/utils.dart';
import '../../../data/models/response_model/visit_response_model.dart';
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
  String? _selectedVisitTypeFilter; // null means "All"
  DateTime? _selectedDateFilter; // null means "All dates"

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
    
    return visits.where((visit) {
      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        final matchesSearch = visit.projectName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                             visit.visitorName.toLowerCase().contains(_searchQuery.toLowerCase());
        if (!matchesSearch) return false;
      }
      
      // Apply status filter
      if (selectedFilter != "All" && visit.status != selectedFilter) {
        return false;
      }
      
      // Apply visit type filter
      if (_selectedVisitTypeFilter != null) {
        final normalizedPurpose = visit.purpose.toLowerCase().replaceAll('_', ' ');
        
        bool matchesType = false;
        if (_selectedVisitTypeFilter == 'project_visit') {
          matchesType = normalizedPurpose.contains('project');
        } else if (_selectedVisitTypeFilter == 'office_visit') {
          matchesType = normalizedPurpose.contains('office');
        } else if (_selectedVisitTypeFilter == 'event_visit') {
          matchesType = normalizedPurpose.contains('event');
        }
        
        if (!matchesType) return false;
      }
      
      // Apply date filter
      if (_selectedDateFilter != null) {
        try {
          // Parse visit date - API format: "dd/MM/yy hh:mm a" (e.g., "22/12/25 05:51 PM")
          String raw = visit.visitDateTime.trim();
          if (raw.contains('+')) {
            raw = raw.split('+')[0];
          }
          
          DateTime? visitDate;
          
          // Try parsing with the API format first: "dd/MM/yy hh:mm a"
          try {
            visitDate = DateFormat('dd/MM/yy hh:mm a').parse(raw);
          } catch (_) {
            // Try alternative format: "dd/MM/yy HH:mm" (24-hour format)
            try {
              visitDate = DateFormat('dd/MM/yy HH:mm').parse(raw);
            } catch (_) {
              // Try ISO format
              try {
                visitDate = DateTime.parse(raw);
              } catch (_) {
                // Try extracting date part from formats like "dd/MM/yy"
                final dateMatch = RegExp(r'(\d{2}/\d{2}/\d{2})').firstMatch(raw);
                if (dateMatch != null) {
                  try {
                    visitDate = DateFormat('dd/MM/yy').parse(dateMatch.group(1)!);
                  } catch (_) {
                    // Try with 4-digit year
                    final dateMatch4 = RegExp(r'(\d{2}/\d{2}/\d{4})').firstMatch(raw);
                    if (dateMatch4 != null) {
                      try {
                        visitDate = DateFormat('dd/MM/yyyy').parse(dateMatch4.group(1)!);
                      } catch (_) {
                        visitDate = null;
                      }
                    }
                  }
                }
              }
            }
          }
          
          if (visitDate != null) {
            // Compare only the date part (ignore time)
            final selectedDateOnly = DateTime(
              _selectedDateFilter!.year,
              _selectedDateFilter!.month,
              _selectedDateFilter!.day,
            );
            final visitDateOnly = DateTime(
              visitDate.year,
              visitDate.month,
              visitDate.day,
            );
            
            if (visitDateOnly != selectedDateOnly) {
              return false;
            }
          } else {
            // If date parsing fails, exclude the visit
            return false;
          }
        } catch (e) {
          // If date parsing fails, exclude the visit
          debugPrint('Date filter parsing error: $e for date: ${visit.visitDateTime}');
          return false;
        }
      }
      
      return true;
    }).toList();
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

          // Search field on first line
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
                hintText: "Search...",
                border: InputBorder.none,
                prefixIcon: const Icon(Icons.search, color: AppColors.primaryColor),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Filters on next line
          Row(
            children: [
              // Visit Type Filter
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.secondaryTextColor,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedVisitTypeFilter,
                    dropdownColor: Colors.white,
                    decoration: InputDecoration(
                      hintText: "Type",
                      hintStyle: const TextStyle(fontSize: 14, color: AppColors.secondaryTextColor),
                      prefixIcon: const Icon(Icons.category, size: 20, color: AppColors.primaryTextColor),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('All', style: TextStyle(fontSize: 14, color: AppColors.primaryTextColor)),
                      ),
                      const DropdownMenuItem<String>(
                        value: 'project_visit',
                        child: Text('Project', style: TextStyle(fontSize: 14, color: AppColors.primaryTextColor)),
                      ),
                      const DropdownMenuItem<String>(
                        value: 'office_visit',
                        child: Text('Office', style: TextStyle(fontSize: 14, color: AppColors.primaryTextColor)),
                      ),
                      const DropdownMenuItem<String>(
                        value: 'event_visit',
                        child: Text('Event', style: TextStyle(fontSize: 14, color: AppColors.primaryTextColor)),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedVisitTypeFilter = value;
                      });
                    },
                    isExpanded: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Date Filter
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.secondaryTextColor,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDateFilter ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: AppColors.primaryColor, // header & OK button
                                onPrimary: Colors.white,
                                surface: Colors.white,
                                onSurface: Colors.black, // ✅ dialog text
                              ),

                              // ✅ THIS fixes the typed date text color
                              textTheme: const TextTheme(
                                bodyLarge: TextStyle(color: Colors.black),
                                bodyMedium: TextStyle(color: Colors.black),
                              ),

                              // ✅ Input field (Enter Date) text & hint color
                              inputDecorationTheme: const InputDecorationTheme(
                                hintStyle: TextStyle(color: Colors.black54),
                                labelStyle: TextStyle(color: Colors.black),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );

                      if (picked != null) {
                        setState(() {
                          _selectedDateFilter = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 20, color: AppColors.primaryTextColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedDateFilter == null
                                  ? 'Date'
                                  : Utils.formatDate(_selectedDateFilter!),
                              style: TextStyle(
                                fontSize: 14,
                                color: _selectedDateFilter == null
                                    ? AppColors.secondaryTextColor
                                    : AppColors.primaryTextColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_selectedDateFilter != null)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 18, color: AppColors.secondaryTextColor),
                              onPressed: () {
                                setState(() {
                                  _selectedDateFilter = null;
                                });
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
    final screenWidth = MediaQuery.of(context).size.width;
    final maxContentWidth = 1400.0;
    
    if (visitsState.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading visits...',
              style: TextStyle(
                color: AppColors.secondaryTextColor,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }
    
    if (visitsState.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading visits',
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                visitsState.error!,
                style: TextStyle(
                  color: AppColors.secondaryTextColor,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  if (!_isDisposed && mounted) {
                    ref.read(visitsControllerProvider.notifier).loadVisits();
                  }
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
      );
    }
    
    final filteredVisits = _getFilteredVisits(visitsState.visits);
    final totalVisits = visitsState.visits.length;
    
    // Count visits by type
    final visitTypeCounts = _getVisitTypeCounts(filteredVisits);

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(visitsControllerProvider.notifier).loadVisits();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth > maxContentWidth ? 40.0 : 24.0,
          vertical: 24.0,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section with Title and Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Visits",
                          style: TextStyle(
                            color: AppColors.primaryTextColor,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "View and manage all visitor visits",
                          style: TextStyle(
                            color: AppColors.secondaryTextColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primaryColor.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 20,
                            color: AppColors.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "${filteredVisits.length} ${filteredVisits.length == 1 ? 'Visit' : 'Visits'}",
                            style: TextStyle(
                              color: AppColors.primaryColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Stats Cards Row
                Row(
                  children: [
                    Expanded(
                      child: _buildStatsCard(
                        title: "Total Visits",
                        count: totalVisits.toString(),
                        icon: Icons.people,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildVisitTypeStatsCard(visitTypeCounts),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Visits Table Container - Enhanced
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
                            // Search field
                            Expanded(
                              flex: 3,
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
                                    hintText: "Search by project name, visitor name, or phone...",
                                    hintStyle: TextStyle(
                                      color: AppColors.secondaryTextColor.withValues(alpha: 0.6),
                                      fontSize: 15,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.search,
                                      size: 22,
                                      color: AppColors.secondaryTextColor,
                                    ),
                                    suffixIcon: _searchQuery.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(
                                              Icons.clear,
                                              size: 20,
                                              color: AppColors.secondaryTextColor,
                                            ),
                                            onPressed: () {
                                              _searchController.clear();
                                              setState(() {
                                                _searchQuery = '';
                                              });
                                            },
                                          )
                                        : null,
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
                            // Visit Type Filter
                            Container(
                              width: 180,
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
                                initialValue: _selectedVisitTypeFilter,
                                dropdownColor: Colors.white,
                                decoration: InputDecoration(
                                  hintText: "Visit Type",
                                  hintStyle: TextStyle(
                                    color: AppColors.secondaryTextColor.withValues(alpha: 0.6),
                                    fontSize: 15,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.category,
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
                                    child: Text('All Types', style: TextStyle(fontSize: 15, color: AppColors.primaryTextColor)),
                                  ),
                                  const DropdownMenuItem<String>(
                                    value: 'project_visit',
                                    child: Text('Project Visit', style: TextStyle(fontSize: 15, color: AppColors.primaryTextColor)),
                                  ),
                                  const DropdownMenuItem<String>(
                                    value: 'office_visit',
                                    child: Text('Office Visit', style: TextStyle(fontSize: 15, color: AppColors.primaryTextColor)),
                                  ),
                                  const DropdownMenuItem<String>(
                                    value: 'event_visit',
                                    child: Text('Event Visit', style: TextStyle(fontSize: 15, color: AppColors.primaryTextColor)),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedVisitTypeFilter = value;
                                  });
                                },
                                isExpanded: true,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Date Filter
                            Container(
                              width: 180,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.textFieldBGColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: InkWell(
                                onTap: () async {
                                  final DateTime? picked = await showDatePicker(
                                    context: context,
                                    initialDate: _selectedDateFilter ?? DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: ColorScheme.light(
                                            primary: AppColors.primaryColor,
                                            onPrimary: Colors.white,
                                            surface: Colors.white,
                                            onSurface: AppColors.primaryTextColor,
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _selectedDateFilter = picked;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today,
                                        size: 22,
                                        color: AppColors.secondaryTextColor,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _selectedDateFilter == null
                                              ? 'Select Date'
                                              : Utils.formatDate(_selectedDateFilter!),
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: _selectedDateFilter == null
                                                ? AppColors.secondaryTextColor.withValues(alpha: 0.6)
                                                : AppColors.primaryTextColor,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (_selectedDateFilter != null)
                                        IconButton(
                                          icon: const Icon(
                                            Icons.clear,
                                            size: 18,
                                            color: AppColors.secondaryTextColor,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _selectedDateFilter = null;
                                            });
                                          },
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Show empty state message when there are no visits
                      if (filteredVisits.isEmpty)
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
                                  'No visits found',
                                  style: TextStyle(
                                    color: AppColors.primaryTextColor,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _searchQuery.isEmpty
                                      ? 'Get started by adding your first visit'
                                      : 'Try adjusting your search terms',
                                  style: TextStyle(
                                    color: AppColors.secondaryTextColor,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        _buildEnhancedVisitorsTable(filteredVisits),
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

  Widget _buildStatsCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
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
        padding: const EdgeInsets.all(24),
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
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        count,
                        style: const TextStyle(
                          color: AppColors.primaryTextColor,
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 28,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Map<String, int> _getVisitTypeCounts(List<Visit> visits) {
    int projectCount = 0;
    int officeCount = 0;
    int eventCount = 0;

    for (var visit in visits) {
      final normalizedType = visit.purpose.toLowerCase().replaceAll('_', ' ');
      
      // Check in priority order to avoid double counting
      // Check for "project visit" or just "project"
      if (normalizedType.contains('project')) {
        projectCount++;
      } 
      // Check for "office visit" or just "office"
      else if (normalizedType.contains('office')) {
        officeCount++;
      } 
      // Check for "event visit" or just "event"
      else if (normalizedType.contains('event')) {
        eventCount++;
      }
    }

    return {
      'project': projectCount,
      'office': officeCount,
      'event': eventCount,
    };
  }

  Widget _buildVisitTypeStatsCard(Map<String, int> counts) {
    return Container(
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
        padding: const EdgeInsets.all(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text(
            //   "Visit Types",
            //   style: TextStyle(
            //     color: AppColors.secondaryTextColor,
            //     fontSize: 15,
            //     fontWeight: FontWeight.w500,
            //   ),
            // ),
            // const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildVisitTypeItem(
                    label: "Project Visit",
                    count: counts['project'] ?? 0,
                    color: Colors.deepOrange,
                    icon: Icons.construction,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: _buildVisitTypeItem(
                    label: "Office Visit",
                    count: counts['office'] ?? 0,
                    color: Colors.blue,
                    icon: Icons.business,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: _buildVisitTypeItem(
                    label: "Event Visit",
                    count: counts['event'] ?? 0,
                    color: Colors.pink,
                    icon: Icons.event,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitTypeItem({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                count.toString(),
                style: TextStyle(
                  color: AppColors.primaryTextColor,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppColors.secondaryTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedVisitorsTable(List<Visit> visits) {
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
              SizedBox(
                width: 100,
                child: _buildTableHeader("Photo"),
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
              Expanded(
                flex: 1,
                child: _buildTableHeader("Visit Type"),
              ),
              SizedBox(
                width: 80,
                child: _buildTableHeader("Actions"),
              ),
            ],
          ),
        ),
        
        // Table Rows
        ...visits.asMap().entries.map((entry) {
          final visit = entry.value;
          return _buildEnhancedVisitRow(visit);
        }),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildTableHeader(String text) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.primaryTextColor,
        fontWeight: FontWeight.w600,
        fontSize: 14,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildEnhancedVisitRow(Visit visit) {
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
          onTap: () {
            if (!_isDisposed && mounted) {
              context.push(Routes.visitDetailScreen, extra: visit);
            }
          },
          hoverColor: AppColors.textFieldBGColor.withValues(alpha: 0.5),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 100,
                  child: _buildVisitorPhoto(visit.visitorPhoto),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Text(
                    visit.visitorName,
                    style: const TextStyle(
                      color: AppColors.primaryTextColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                          visit.projectName,
                          style: const TextStyle(
                            color: AppColors.primaryTextColor,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 18,
                        color: AppColors.secondaryTextColor,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          Utils.formatDateTime(visit.visitDateTime),
                          style: TextStyle(
                            color: AppColors.secondaryTextColor,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: _buildVisitTypeChip(visit.purpose),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 80,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          if (!_isDisposed && mounted) {
                            context.push(Routes.visitDetailScreen, extra: visit);
                          }
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
                              const Icon(
                                Icons.visibility,
                                size: 18,
                                color: AppColors.primaryColor,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'View',
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatVisitType(String visitType) {
    if (visitType.isEmpty) return 'N/A';
    
    // Replace underscores with spaces and capitalize each word
    return visitType
        .split('_')
        .map((word) => word.isEmpty 
            ? '' 
            : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  Color _getVisitTypeColor(String visitType) {
    final normalizedType = visitType.toLowerCase().replaceAll('_', ' ');
    
    // Assign different colors based on visit type
    if (normalizedType.contains('office') || normalizedType.contains('office visit')) {
      return Colors.blue;
    } else if (normalizedType.contains('site') || normalizedType.contains('site visit')) {
      return Colors.green;
    } else if (normalizedType.contains('project') || normalizedType.contains('project visit')) {
      return Colors.deepOrange;
    } else if (normalizedType.contains('event') || normalizedType.contains('event visit')) {
      return Colors.pink;
    } else if (normalizedType.contains('meeting') || normalizedType.contains('meeting')) {
      return Colors.purple;
    } else if (normalizedType.contains('inspection') || normalizedType.contains('inspection')) {
      return Colors.orange;
    } else if (normalizedType.contains('follow') || normalizedType.contains('follow up')) {
      return Colors.teal;
    } else if (normalizedType.contains('consultation') || normalizedType.contains('consultation')) {
      return Colors.indigo;
    } else {
      // Default color for other types
      return AppColors.primaryColor;
    }
  }

  Widget _buildVisitTypeChip(String visitType) {
    final formattedText = _formatVisitType(visitType);
    final chipColor = _getVisitTypeColor(visitType);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: chipColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        formattedText,
        style: TextStyle(
          color: chipColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildVisitorPhoto(String? photoUrl) {
    return Container(
      height: 56,
      width: 56,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
       // shape: BoxShape.circle,
        // border: Border.all(
        //   color: Colors.grey.withValues(alpha: 0.2),
        //   width: 2,
        // ),
        color: Colors.grey[50],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      
        child: photoUrl != null && photoUrl.isNotEmpty
            ?  _buildWebCompatibleImage(photoUrl, 56, 56)
              
            : Center(
                child: Image.asset(
                  ImageAssets.highFlyLogo,
                  fit: BoxFit.cover,
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
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
      borderRadius: 1,
    );
  }

  /// Builds a user-friendly empty state message when there are no visitors
  Widget _buildEmptyStateMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(60.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.group_outlined,
              size: 72,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            Text(
              "No Visits Found",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "There are currently no visit records to display.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Visits will appear here once they are scheduled or checked in.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                if (!_isDisposed && mounted) {
                  ref.read(visitsControllerProvider.notifier).loadVisits();
                }
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh Data'),
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
    );
  }
}
