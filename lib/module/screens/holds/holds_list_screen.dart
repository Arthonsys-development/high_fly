import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/constant/app_colors.dart';
import '../../../data/models/hold_list_model.dart';
import '../../providers/holds_provider.dart';
import '../../utils/responsive.dart';
import 'hold_detail_screen.dart';

class HoldsListScreen extends ConsumerStatefulWidget {
  const HoldsListScreen({super.key});

  @override
  ConsumerState<HoldsListScreen> createState() => _HoldsListScreenState();
}

class _HoldsListScreenState extends ConsumerState<HoldsListScreen>
    with WidgetsBindingObserver {
  bool _isDisposed = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Load holds when the screen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed && mounted) {
        ref.read(holdsControllerProvider.notifier).loadHolds();
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
        ref.read(holdsControllerProvider.notifier).loadHolds();
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

  List<HoldListModel> _getFilteredHolds(List<HoldListModel> holds) {
    if (_isDisposed || !mounted) return [];
    
    if (_searchQuery.isEmpty) return holds;
    
    return holds.where((hold) {
      return hold.plotCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             hold.customerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             hold.customerPhone.contains(_searchQuery) ||
             hold.statusDisplay.toLowerCase().contains(_searchQuery.toLowerCase());
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
    final holdsState = ref.watch(holdsControllerProvider);
    
    if (holdsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (holdsState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: ${holdsState.error}', style: const TextStyle(color: Colors.black)),
            ElevatedButton(
              onPressed: () {
                if (!_isDisposed && mounted) {
                  ref.read(holdsControllerProvider.notifier).loadHolds();
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    final filteredHolds = _getFilteredHolds(holdsState.holds);

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(holdsControllerProvider.notifier).loadHolds();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Holds",
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
                style: TextStyle(color: AppColors.primaryColor, fontSize: 18),
                decoration: InputDecoration(
                  hintText: "Search...",
                  border: InputBorder.none,
                  prefixIcon: const Icon(Icons.search, color: AppColors.primaryColor),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Holds List
            if (filteredHolds.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Text(
                    'No holds found',
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
                itemCount: filteredHolds.length,
                itemBuilder: (context, index) {
                  final hold = filteredHolds[index];
                  return _buildHoldCard(hold);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    final holdsState = ref.watch(holdsControllerProvider);
    
    if (holdsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (holdsState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: ${holdsState.error}', style: const TextStyle(color: Colors.black)),
            ElevatedButton(
              onPressed: () {
                if (!_isDisposed && mounted) {
                  ref.read(holdsControllerProvider.notifier).loadHolds();
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    final filteredHolds = _getFilteredHolds(holdsState.holds);

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(holdsControllerProvider.notifier).loadHolds();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Holds",
              style: TextStyle(
                color: AppColors.primaryTextColor,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),

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
                style: TextStyle(color: AppColors.primaryColor),
                decoration: InputDecoration(
                  hintText: "Search...",
                  border: InputBorder.none,
                  prefixIcon: const Icon(Icons.search, color: AppColors.primaryColor),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Holds Grid
            if (filteredHolds.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Text(
                    'No holds found',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.lightGreyColor,
                    ),
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                itemCount: filteredHolds.length,
                itemBuilder: (context, index) {
                  final hold = filteredHolds[index];
                  return _buildHoldCard(hold);
                },
              ),
          ],
        ),
      ),
    );
  }

  Color _getHoldStatusColor(HoldListModel hold) {
    final status = hold.status.toLowerCase();
    
    // Check status first, then isExpired flag
    if (status == 'active') {
      return Colors.green;
    } else if (status == 'expired' || status == 'inactive' || hold.isExpired) {
      return Colors.red;
    } else {
      return Colors.orange;
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

  Widget _buildHoldCard(HoldListModel hold) {
    final statusColor = _getHoldStatusColor(hold);
    
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
              builder: (context) => HoldDetailScreen(hold: hold),
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
                      'Plot: ${hold.plotCode}',
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
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _formatStatusDisplay(hold.statusDisplay),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoRow('Customer', hold.customerName),
              const SizedBox(height: 8),
              _buildInfoRow('Phone', hold.customerPhone),
              const SizedBox(height: 8),
              _buildInfoRow('Hold Until', hold.holdUntil),
              const SizedBox(height: 8),
              _buildInfoRow('Amount', '₹${hold.holdAmount}'),
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

