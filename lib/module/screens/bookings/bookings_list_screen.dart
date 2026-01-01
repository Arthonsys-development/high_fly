import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../config/constant/app_colors.dart';
import '../../../config/utils.dart';
import '../../../data/models/booking_list_model.dart';
import '../../providers/bookings_provider.dart';
import '../../utils/responsive.dart';
import 'booking_detail_screen.dart';

class BookingsListScreen extends ConsumerStatefulWidget {
  const BookingsListScreen({super.key});

  @override
  ConsumerState<BookingsListScreen> createState() => _BookingsListScreenState();
}

class _BookingsListScreenState extends ConsumerState<BookingsListScreen>
    with WidgetsBindingObserver {
  bool _isDisposed = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedStatusFilter; // null means "All"
  DateTime? _selectedDateFilter; // null means "All dates"

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Load bookings when the screen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed && mounted) {
        ref.read(bookingsControllerProvider.notifier).loadBookings();
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
    if (state == AppLifecycleState.resumed) {
      if (!_isDisposed) {
        ref.read(bookingsControllerProvider.notifier).loadBookings();
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  List<BookingListModel> _getFilteredBookings(List<BookingListModel> bookings) {
    if (_isDisposed || !mounted) return [];
    
    return bookings.where((booking) {
      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        final projectName = booking.project?.name ?? '';
        final matchesSearch = booking.plotCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                             booking.customerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                             booking.customerPhone.contains(_searchQuery) ||
                             booking.statusDisplay.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                             projectName.toLowerCase().contains(_searchQuery.toLowerCase());
        if (!matchesSearch) return false;
      }
      
      // Apply status filter - using statusDisplay
      if (_selectedStatusFilter != null) {
        final statusDisplay = booking.statusDisplay.toLowerCase();
        
        if (_selectedStatusFilter == 'Active') {
          if (statusDisplay != 'active') return false;
        } else if (_selectedStatusFilter == 'Completed/Sold') {
          if (statusDisplay != 'completed/sold') return false;
        } else if (_selectedStatusFilter == 'Cancelled') {
          if (statusDisplay != 'cancelled') return false;
        }
      }
      
      // Apply date filter
      if (_selectedDateFilter != null) {
        try {
          String raw = booking.bookingDate.trim();
          if (raw.contains('+')) {
            raw = raw.split('+')[0];
          }
          
          DateTime? bookingDate;
          
          // Try parsing with the API format first: "dd/MM/yy hh:mm a"
          try {
            bookingDate = DateFormat('dd/MM/yy hh:mm a').parse(raw);
          } catch (_) {
            // Try alternative format: "dd/MM/yy HH:mm" (24-hour format)
            try {
              bookingDate = DateFormat('dd/MM/yy HH:mm').parse(raw);
            } catch (_) {
              // Try ISO format
              try {
                bookingDate = DateTime.parse(raw);
              } catch (_) {
                // Try extracting date part from formats like "dd/MM/yy"
                final dateMatch = RegExp(r'(\d{2}/\d{2}/\d{2})').firstMatch(raw);
                if (dateMatch != null) {
                  try {
                    bookingDate = DateFormat('dd/MM/yy').parse(dateMatch.group(1)!);
                  } catch (_) {
                    // Try with 4-digit year
                    final dateMatch4 = RegExp(r'(\d{2}/\d{2}/\d{4})').firstMatch(raw);
                    if (dateMatch4 != null) {
                      try {
                        bookingDate = DateFormat('dd/MM/yyyy').parse(dateMatch4.group(1)!);
                      } catch (_) {
                        bookingDate = null;
                      }
                    }
                  }
                }
              }
            }
          }
          
          if (bookingDate != null) {
            // Compare only the date part (ignore time)
            final selectedDateOnly = DateTime(
              _selectedDateFilter!.year,
              _selectedDateFilter!.month,
              _selectedDateFilter!.day,
            );
            final bookingDateOnly = DateTime(
              bookingDate.year,
              bookingDate.month,
              bookingDate.day,
            );
            
            if (bookingDateOnly != selectedDateOnly) {
              return false;
            }
          } else {
            // If date parsing fails, exclude the booking
            return false;
          }
        } catch (e) {
          // If date parsing fails, exclude the booking
          debugPrint('Date filter parsing error: $e for date: ${booking.bookingDate}');
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
    final bookingsState = ref.watch(bookingsControllerProvider);
    
    if (bookingsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (bookingsState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: ${bookingsState.error}', style: const TextStyle(color: Colors.black)),
            ElevatedButton(
              onPressed: () {
                if (!_isDisposed && mounted) {
                  ref.read(bookingsControllerProvider.notifier).loadBookings();
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    final filteredBookings = _getFilteredBookings(bookingsState.bookings);

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(bookingsControllerProvider.notifier).loadBookings();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Bookings",
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
                // Status Filter
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
                      initialValue: _selectedStatusFilter,
                      dropdownColor: Colors.white,
                      decoration: InputDecoration(
                        hintText: "Status",
                        hintStyle: const TextStyle(fontSize: 14, color: AppColors.secondaryTextColor),
                        prefixIcon: const Icon(Icons.filter_list, size: 20, color: AppColors.primaryTextColor),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All', style: TextStyle(fontSize: 14, color: AppColors.primaryTextColor)),
                        ),
                        // const DropdownMenuItem<String>(
                        //   value: 'Active',
                        //   child: Text('Active', style: TextStyle(fontSize: 14, color: AppColors.primaryTextColor)),
                        // ),
                        const DropdownMenuItem<String>(
                          value: 'Completed/Sold',
                          child: Text('Completed/Sold', style: TextStyle(fontSize: 14, color: AppColors.primaryTextColor)),
                        ),
                        const DropdownMenuItem<String>(
                          value: 'Cancelled',
                          child: Text('Cancelled', style: TextStyle(fontSize: 14, color: AppColors.primaryTextColor)),
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

            // Bookings List
            if (filteredBookings.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Text(
                    'No bookings found',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.lightGreyColor,
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredBookings.length,
                itemBuilder: (context, index) {
                  final booking = filteredBookings[index];
                  return _buildBookingCard(booking);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    final bookingsState = ref.watch(bookingsControllerProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final maxContentWidth = 1400.0;
    
    if (bookingsState.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading bookings...',
              style: TextStyle(
                color: AppColors.secondaryTextColor,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }
    
    if (bookingsState.error != null) {
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
                'Error loading bookings',
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                bookingsState.error!,
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
                    ref.read(bookingsControllerProvider.notifier).loadBookings();
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
    
    final filteredBookings = _getFilteredBookings(bookingsState.bookings);
    final totalBookings = bookingsState.bookings.length;
    
    // Count bookings by status
    final pendingCount = bookingsState.bookings.where((b) {
      final status = b.status.toLowerCase();
      return status == 'pending' || status == 'processing';
    }).length;
    
    final completedCount = bookingsState.bookings.where((b) {
      final status = b.status.toLowerCase();
      return status == 'completed' || status == 'sold';
    }).length;
    
    final cancelledCount = bookingsState.bookings.where((b) {
      final status = b.status.toLowerCase();
      return status == 'cancelled' || status == 'canceled';
    }).length;
    
    final otherCount = totalBookings - pendingCount - completedCount - cancelledCount;

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(bookingsControllerProvider.notifier).loadBookings();
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
                          "Bookings",
                          style: TextStyle(
                            color: AppColors.primaryTextColor,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "View and manage all bookings",
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
                            Icons.book_online,
                            size: 20,
                            color: AppColors.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "${filteredBookings.length} ${filteredBookings.length == 1 ? 'Booking' : 'Bookings'}",
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

                // Stats Cards Row - Status Counts
                Row(
                  children: [
                    Expanded(
                      child: _buildStatsCard(
                        title: "Total",
                        count: totalBookings.toString(),
                        icon: Icons.book_online,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    if (pendingCount > 0) ...[
                      const SizedBox(width: 20),
                      Expanded(
                        child: _buildStatsCard(
                          title: "Pending",
                          count: pendingCount.toString(),
                          icon: Icons.pending,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                    if (completedCount > 0) ...[
                      const SizedBox(width: 20),
                      Expanded(
                        child: _buildStatsCard(
                          title: "Completed",
                          count: completedCount.toString(),
                          icon: Icons.check_circle,
                          color: Colors.green,
                        ),
                      ),
                    ],
                    if (cancelledCount > 0) ...[
                      const SizedBox(width: 20),
                      Expanded(
                        child: _buildStatsCard(
                          title: "Cancelled",
                          count: cancelledCount.toString(),
                          icon: Icons.cancel,
                          color: Colors.red,
                        ),
                      ),
                    ],
                    if (otherCount > 0) ...[
                      const SizedBox(width: 20),
                      Expanded(
                        child: _buildStatsCard(
                          title: "Other",
                          count: otherCount.toString(),
                          icon: Icons.more_horiz,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 32),

                // Bookings Container - Enhanced
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
                                    hintText: "Search by plot code, customer name, phone...",
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
                            // Status Filter
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
                                initialValue: _selectedStatusFilter,
                                dropdownColor: Colors.white,
                                decoration: InputDecoration(
                                  hintText: "Status",
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
                                  // const DropdownMenuItem<String>(
                                  //   value: 'Active',
                                  //   child: Text('Active', style: TextStyle(fontSize: 15, color: AppColors.primaryTextColor)),
                                  // ),
                                  const DropdownMenuItem<String>(
                                    value: 'Completed/Sold',
                                    child: Text('Completed/Sold', style: TextStyle(fontSize: 15, color: AppColors.primaryTextColor)),
                                  ),
                                  const DropdownMenuItem<String>(
                                    value: 'Cancelled',
                                    child: Text('Cancelled', style: TextStyle(fontSize: 15, color: AppColors.primaryTextColor)),
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

                      // Bookings Grid
                      if (filteredBookings.isEmpty)
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
                                  'No bookings found',
                                  style: TextStyle(
                                    color: AppColors.primaryTextColor,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try adjusting your search or filters',
                                  style: TextStyle(
                                    color: AppColors.secondaryTextColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 1.2,
                            ),
                            itemCount: filteredBookings.length,
                            itemBuilder: (context, index) {
                              final booking = filteredBookings[index];
                              return _buildBookingCard(booking);
                            },
                          ),
                        ),
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

  Color _getBookingStatusColor(BookingListModel booking) {
    final status = booking.status.toLowerCase();
    if (status == 'cancelled' || status == 'canceled') {
      return Colors.red;
    } else if (status == 'completed' || status == 'sold') {
      return Colors.green;
    } else if (status == 'pending' || status == 'processing') {
      return Colors.orange;
    } else {
      return Colors.blue;
    }
  }

  String _formatStatusDisplay(String statusDisplay) {
    if (statusDisplay.isEmpty) return statusDisplay;
    
    // If it contains "/", capitalize each part separately
    if (statusDisplay.contains('/')) {
      return statusDisplay.split('/').map((part) {
        return part.trim().isEmpty 
            ? part 
            : part.trim()[0].toUpperCase() + part.trim().substring(1).toLowerCase();
      }).join('/');
    }
    
    // Capitalize first letter, rest lowercase
    return statusDisplay[0].toUpperCase() + statusDisplay.substring(1).toLowerCase();
  }

  Widget _buildBookingCard(BookingListModel booking) {
    final statusColor = _getBookingStatusColor(booking);
    
    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookingDetailScreen(booking: booking),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Plot: ${booking.plotCode}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryTextColor,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _formatStatusDisplay(booking.statusDisplay),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              if (booking.project != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow('Project', booking.project!.name),
              ],
              const SizedBox(height: 12),
              _buildInfoRow('Customer', booking.customerName),
              const SizedBox(height: 8),
              _buildInfoRow('Phone', booking.customerPhone),
              const SizedBox(height: 8),
              _buildInfoRow('Booking Date', booking.bookingDate),
              const SizedBox(height: 8),
              _buildInfoRow('Amount', '₹${booking.totalAmount}'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.lightGreyColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.primaryTextColor,
              fontWeight: FontWeight.w400,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

